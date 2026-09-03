<#
.SYNOPSIS
  Boots x128, x64sc, xvic, and xplus4, screenshots each after 10s, and stitches
  them into a 1920x1080 (Google Meet background sized) 2x2 grid - saved both
  flipped horizontally (the "meet background") and unreversed.

.PARAMETER ViceBaseFolder
  Root folder of the VICE install (the one containing "bin\x128.exe" etc).
  Must be fully qualified - this is NOT resolved relative to this script's location.

.PARAMETER OutputFile
  Fully qualified path to write the flipped "meet background" PNG to. Parent
  folder is created if missing.

.PARAMETER UnflippedOutputFile
  Fully qualified path to write the unreversed 2x2 grid PNG to. Parent folder
  is created if missing.

.PARAMETER BasicFile
  Optional BASIC listing filename (e.g. "sine.bas") to autostart on every
  emulator. Looked up under BasicFilesRoot: common\<BasicFile> first, then
  <emulator-specific dir>\<BasicFile>. Tokenized to a .prg via VICE's petcat
  and booted with -autostart. Omit to just capture the default READY screen.

.PARAMETER BasicFilesRoot
  Root folder holding the "common", "64", "128", "vic-20", and "plus4"
  subfolders of BASIC listings. Defaults to "basic-files" next to this script.

.PARAMETER CaptureDelaySeconds
  Minimum seconds to wait after each emulator's window appears before it's
  eligible for screenshotting. Default 10. When -BasicFile is given, this is
  just a baseline - the script then polls window content and keeps waiting
  (up to MaxDrawWaitSeconds) until two samples 3s apart match, so a slow
  interpreted BASIC POKE loop (e.g. 64\sine.bas's VIC-II bitmap draw) gets
  however long it actually needs without guessing, and fast ones don't wait
  around either. With no -BasicFile, there's nothing to poll for (the READY
  screen never changes) so this is the only wait.

.PARAMETER MaxDrawWaitSeconds
  Ceiling on the extra content-stabilization polling described above (only
  relevant with -BasicFile). Default 300. If content is still changing every
  poll right up to this deadline, the script gives up waiting and captures
  whatever's on screen.

.EXAMPLE
  .\New-ViceMeetBackground.ps1
  .\New-ViceMeetBackground.ps1 -ViceBaseFolder "D:\Apps\GTK3VICE-3.10-win64" -OutputFile "C:\Backgrounds\vice.png"
  .\New-ViceMeetBackground.ps1 -BasicFile "sine.bas"
#>
param(
    [string]$ViceBaseFolder = "E:\Emu\GTK3VICE-3.10-win64",
    [string]$OutputFile = (Join-Path $env:USERPROFILE "Pictures\Meet Backgrounds\vice_emulators_2x2.png"),
    [string]$UnflippedOutputFile = (Join-Path $env:USERPROFILE "Pictures\Meet Backgrounds\vice_emulators_2x2_unflipped.png"),
    [string]$BasicFile = $null,
    [string]$BasicFilesRoot = (Join-Path $PSScriptRoot "basic-files"),
    [int]$CaptureDelaySeconds = 10,
    [int]$MaxDrawWaitSeconds = 300
)

# ponytail: paths are taken as-is (or defaulted above) rather than derived from
# $PSScriptRoot / Get-Location, so this still works after the script is moved
# or run from an unrelated working directory. BasicFilesRoot is the one
# exception - it's part of this repo, so it's meant to travel with the script.
if (-not [System.IO.Path]::IsPathRooted($ViceBaseFolder)) {
    throw "ViceBaseFolder must be a fully qualified path, got: $ViceBaseFolder"
}
if (-not [System.IO.Path]::IsPathRooted($OutputFile)) {
    throw "OutputFile must be a fully qualified path, got: $OutputFile"
}
if (-not [System.IO.Path]::IsPathRooted($UnflippedOutputFile)) {
    throw "UnflippedOutputFile must be a fully qualified path, got: $UnflippedOutputFile"
}

$binDir = Join-Path $ViceBaseFolder "bin"
if (-not (Test-Path $binDir)) {
    throw "VICE bin folder not found: $binDir"
}

$workDir = Join-Path $env:TEMP ("vice_meet_bg_" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $workDir | Out-Null

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
    [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr hWnd, out RECT lpRect);
    [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr hWnd, ref POINT lpPoint);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr hWnd, IntPtr hdcBlt, uint nFlags);
    [DllImport("user32.dll")] public static extern IntPtr SetProcessDpiAwarenessContext(IntPtr value);
    public struct RECT { public int Left, Top, Right, Bottom; }
    public struct POINT { public int X, Y; }
}
"@
Add-Type -AssemblyName System.Drawing

# per-monitor-v2 DPI awareness so GetWindowRect/GetClientRect return real physical
# pixels matching what PrintWindow renders (mismatched DPI virtualization otherwise
# crops the right/bottom edge of the capture)
[Win32]::SetProcessDpiAwarenessContext([IntPtr](-4)) | Out-Null

# emulator -> NTSC or PAL. xvic stays PAL: this VICE build (3.10) truncates the
# right ~2 character columns of the VIC-20 screen in NTSC mode regardless of
# window size - confirmed it's a render bug, not a capture-crop issue.
$emus = [ordered]@{
    x128    = $true
    x64sc   = $true
    xvic    = $false
    xplus4  = $true
}

# emulator -> basic-files subfolder name, and petcat -w<version> BASIC dialect
# code (these are petcat's own version strings, not sequential numbers - see
# `petcat -k`; x64sc/xvic share plain BASIC V2, xplus4 shares C16's BASIC V3.5)
$emuDirs = @{
    x128    = "128"
    x64sc   = "64"
    xvic    = "vic-20"
    xplus4  = "plus4"
}
$petcatDialect = @{
    x128    = "70"
    x64sc   = "2"
    xvic    = "2"
    xplus4  = "3"
}
# petcat's -w2 dialect covers C64/VIC20/PET's shared keyword set, but its
# built-in load address (petcat -l) defaults to the C64/PET BASIC start
# ($0801) - an unexpanded VIC-20's BASIC RAM starts at $1001, so xvic needs
# an explicit override or the autostarted program lands outside BASIC's
# text pointers and never actually runs
$petcatLoadAddr = @{
    xvic = "1001"
}

function Resolve-BasicFile($emuName, $name) {
    $commonPath = Join-Path $BasicFilesRoot (Join-Path "common" $name)
    if (Test-Path $commonPath) { return $commonPath }
    $emuPath = Join-Path $BasicFilesRoot (Join-Path $emuDirs[$emuName] $name)
    if (Test-Path $emuPath) { return $emuPath }
    throw "Basic file '$name' not found in '$commonPath' or '$emuPath'"
}

function Get-RowStat($bmp, $y, $width) {
    # sample several x columns across the row; True = looks like emulator content
    # (colored border / dark screen), False = looks like the light GTK menu/status bar
    $samples = 0..7 | ForEach-Object { [int]($width * ($_ + 0.5) / 8) }
    $contentVotes = 0
    foreach ($x in $samples) {
        $c = $bmp.GetPixel($x, $y)
        $maxc = [Math]::Max($c.R, [Math]::Max($c.G, $c.B))
        $minc = [Math]::Min($c.R, [Math]::Min($c.G, $c.B))
        $sat = $maxc - $minc
        $bright = ($c.R + $c.G + $c.B) / 3
        if ($sat -gt 30 -or $bright -lt 100) { $contentVotes++ }
    }
    return $contentVotes -ge 5
}

function Get-ContentFingerprint($hwnd, $w, $h) {
    # cheap NxM pixel-grid sample of the current window content, used to
    # detect when a slow autostarted BASIC program has stopped drawing -
    # far cheaper than hashing a full PNG encode of the frame
    $bmp = New-Object System.Drawing.Bitmap -ArgumentList $w, $h
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $hdc = $g.GetHdc()
    [Win32]::PrintWindow($hwnd, $hdc, 2) | Out-Null
    $g.ReleaseHdc($hdc)
    $g.Dispose()
    $sb = New-Object System.Text.StringBuilder
    for ($gy = 0; $gy -lt 24; $gy++) {
        $y = [int]($h * ($gy + 0.5) / 24)
        for ($gx = 0; $gx -lt 32; $gx++) {
            $x = [int]($w * ($gx + 0.5) / 32)
            [void]$sb.Append($bmp.GetPixel($x, $y).ToArgb())
        }
    }
    $bmp.Dispose()
    return $sb.ToString()
}

function Get-EmulatorScreenshot($emuName, $useNtsc, $outFile, $basicPath) {
    $exe = Join-Path $binDir "$emuName.exe"
    if (-not (Test-Path $exe)) { throw "Emulator executable not found: $exe" }

    $argList = @()
    if ($useNtsc) { $argList += "-ntsc" }
    if ($basicPath) {
        # tokenize the ASCII BASIC listing into a machine-specific .prg via
        # VICE's own petcat, then boot straight into it with -autostart
        $petcat = Join-Path $binDir "petcat.exe"
        if (-not (Test-Path $petcat)) { throw "petcat.exe not found: $petcat" }
        $prgPath = Join-Path $workDir "$emuName.prg"
        $petcatArgs = @("-w$($petcatDialect[$emuName])")
        if ($petcatLoadAddr.Contains($emuName)) { $petcatArgs += @("-l", $petcatLoadAddr[$emuName]) }
        $petcatOut = & $petcat @petcatArgs -o $prgPath -- $basicPath 2>&1
        # petcat always exits 0 and still writes a file (silently falling back
        # to a default dialect) even for an unrecognized -w version, so exit
        # code / file existence can't be trusted - the only tell is this text
        if (($petcatOut -join "`n") -match "Unimplemented version") {
            throw "petcat rejected dialect -w$($petcatDialect[$emuName]) for $emuName`: $petcatOut"
        }
        if (-not (Test-Path $prgPath) -or (Get-Item $prgPath).Length -eq 0) {
            throw "petcat failed to tokenize $basicPath -> $prgPath`: $petcatOut"
        }
        $argList += @("-autostart", $prgPath)
    }

    if ($argList.Count -gt 0) {
        $proc = Start-Process -FilePath $exe -ArgumentList $argList -WorkingDirectory $binDir -PassThru
    } else {
        $proc = Start-Process -FilePath $exe -WorkingDirectory $binDir -PassThru
    }

    try {
        $timeout = [DateTime]::Now.AddSeconds(15)
        while ($proc.MainWindowHandle -eq 0 -and [DateTime]::Now -lt $timeout) {
            Start-Sleep -Milliseconds 200
            $proc.Refresh()
        }

        Start-Sleep -Seconds $CaptureDelaySeconds

        $hwnd = $proc.MainWindowHandle
        [Win32]::ShowWindow($hwnd, 9) | Out-Null   # SW_RESTORE

        # some models resize the window a moment after startup - wait for the
        # rect to stop changing so we don't capture mid-resize
        $winRect = New-Object Win32+RECT
        $prevW = -1; $prevH = -1
        for ($i = 0; $i -lt 10; $i++) {
            [Win32]::GetWindowRect($hwnd, [ref]$winRect) | Out-Null
            $w = $winRect.Right - $winRect.Left
            $h = $winRect.Bottom - $winRect.Top
            if ($w -eq $prevW -and $h -eq $prevH) { break }
            $prevW = $w; $prevH = $h
            Start-Sleep -Milliseconds 300
        }

        if ($basicPath) {
            # a booted BASIC program can still be mid-draw well past
            # CaptureDelaySeconds (a slow interpreted POKE loop, say) - poll
            # content instead of trusting a single fixed guess. A byte-level
            # clear/draw loop can advance between two samples without any of
            # the 768 grid points landing on the changed area - one match is
            # not a reliable "done" signal (confirmed live: a real still-mid-
            # draw screen matched once, then kept changing for 6+ more polls)
            # - so require several consecutive matches, up to a generous
            # ceiling on total wait.
            $prevFingerprint = $null
            $stableStreak = 0
            $requiredStreak = 4
            $pollDeadline = [DateTime]::Now.AddSeconds($MaxDrawWaitSeconds)
            while ([DateTime]::Now -lt $pollDeadline) {
                $fp = Get-ContentFingerprint $hwnd $w $h
                if ($fp -eq $prevFingerprint) {
                    $stableStreak++
                    if ($stableStreak -ge $requiredStreak) { break }
                } else {
                    $stableStreak = 0
                }
                $prevFingerprint = $fp
                Start-Sleep -Seconds 3
            }
        }

        # full window capture via PrintWindow (works even if occluded by other windows)
        $full = New-Object System.Drawing.Bitmap -ArgumentList $w, $h
        $g = [System.Drawing.Graphics]::FromImage($full)
        $hdc = $g.GetHdc()
        [Win32]::PrintWindow($hwnd, $hdc, 2) | Out-Null   # PW_RENDERFULLCONTENT
        $g.ReleaseHdc($hdc)
        $g.Dispose()

        # client rect strips the OS title bar/border
        $clientRect = New-Object Win32+RECT
        [Win32]::GetClientRect($hwnd, [ref]$clientRect) | Out-Null
        $origin = New-Object Win32+POINT
        $origin.X = 0; $origin.Y = 0
        [Win32]::ClientToScreen($hwnd, [ref]$origin) | Out-Null
        $offX = $origin.X - $winRect.Left
        $offY = $origin.Y - $winRect.Top
        $cw = $clientRect.Right - $clientRect.Left
        $ch = $clientRect.Bottom - $clientRect.Top

        $client = $full.Clone((New-Object System.Drawing.Rectangle $offX, $offY, $cw, $ch), $full.PixelFormat)
        $full.Dispose()

        # crop off the GTK menu bar (top)
        $menuBottom = 0
        for ($y = 0; $y -lt [Math]::Min(120, $ch); $y++) {
            if (Get-RowStat $client $y $cw) { $menuBottom = $y; break }
        }
        $screen = $client.Clone((New-Object System.Drawing.Rectangle 0, $menuBottom, $cw, ($ch - $menuBottom)), $client.PixelFormat)
        $client.Dispose()
        $sh = $ch - $menuBottom

        # crop off the GTK status bar (bottom: warp/pause/fps/etc.)
        $screenBottom = $sh - 1
        for ($y = $sh - 1; $y -ge 0; $y--) {
            if (Get-RowStat $screen $y $cw) { $screenBottom = $y; break }
        }
        $final = $screen.Clone((New-Object System.Drawing.Rectangle 0, 0, $cw, ($screenBottom + 1)), $screen.PixelFormat)
        $screen.Dispose()

        $final.Save($outFile, [System.Drawing.Imaging.ImageFormat]::Png)
        $final.Dispose()
        Write-Output "Captured $emuName -> $outFile"
    }
    finally {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }
}

try {
    $shots = [ordered]@{}
    foreach ($emu in $emus.Keys) {
        $outFile = Join-Path $workDir "$emu.png"
        $basicPath = $null
        if ($BasicFile) { $basicPath = Resolve-BasicFile -emuName $emu -name $BasicFile }
        Get-EmulatorScreenshot -emuName $emu -useNtsc $emus[$emu] -outFile $outFile -basicPath $basicPath
        $shots[$emu] = $outFile
        Start-Sleep -Milliseconds 500
    }

    # stitch into a 1920x1080 2x2 grid (Google Meet virtual background size), flipped horizontally
    $canvasW = 1920
    $canvasH = 1080
    $cellW = [int]($canvasW / 2)
    $cellH = [int]($canvasH / 2)

    $imgs = $shots.Values | ForEach-Object { [System.Drawing.Image]::FromFile($_) }
    $grid = New-Object System.Drawing.Bitmap -ArgumentList $canvasW, $canvasH
    $g = [System.Drawing.Graphics]::FromImage($grid)
    $g.Clear([System.Drawing.Color]::Black)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

    $positions = @(
        @{x=0; y=0}, @{x=$cellW; y=0},
        @{x=0; y=$cellH}, @{x=$cellW; y=$cellH}
    )
    for ($i = 0; $i -lt 4; $i++) {
        $img = $imgs[$i]
        # scale to fit inside the cell (preserve aspect ratio), then center
        $scale = [Math]::Min($cellW / $img.Width, $cellH / $img.Height)
        $dw = [int]($img.Width * $scale)
        $dh = [int]($img.Height * $scale)
        $dx = $positions[$i].x + [int](($cellW - $dw) / 2)
        $dy = $positions[$i].y + [int](($cellH - $dh) / 2)
        $g.DrawImage($img, $dx, $dy, $dw, $dh)
    }
    $g.Dispose()
    $imgs | ForEach-Object { $_.Dispose() }

    $unflippedParent = Split-Path -Parent $UnflippedOutputFile
    if ($unflippedParent -and -not (Test-Path $unflippedParent)) {
        New-Item -ItemType Directory -Force -Path $unflippedParent | Out-Null
    }
    $grid.Save($UnflippedOutputFile, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Output "Saved -> $UnflippedOutputFile"

    $grid.RotateFlip([System.Drawing.RotateFlipType]::RotateNoneFlipX)

    $outParent = Split-Path -Parent $OutputFile
    if ($outParent -and -not (Test-Path $outParent)) {
        New-Item -ItemType Directory -Force -Path $outParent | Out-Null
    }
    $grid.Save($OutputFile, [System.Drawing.Imaging.ImageFormat]::Png)
    $grid.Dispose()
    Write-Output "Saved -> $OutputFile"
}
finally {
    Remove-Item -Recurse -Force $workDir -ErrorAction SilentlyContinue
}
