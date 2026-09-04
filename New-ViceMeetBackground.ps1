<#
.SYNOPSIS
  Boots x128, x64sc, xvic, and xplus4 (via New-ViceScreenshot.ps1, one
  isolated process per emulator), screenshots each, and stitches them into a
  1920x1080 (Google Meet background sized) 2x2 grid - saved both flipped
  horizontally (the "meet background") and unreversed.

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
  emulator - see New-ViceScreenshot.ps1's -BasicFile help for the lookup
  rules. Omit to just capture the default READY screen.

.PARAMETER BasicFilesRoot
  Root folder holding the "common", "64", "128", "vic-20", and "plus4"
  subfolders of BASIC listings. Defaults to "basic-files" next to this script.

.PARAMETER CaptureDelaySeconds
  Passed through to New-ViceScreenshot.ps1 for each emulator - see its help
  for details. Default 10.

.PARAMETER MaxDrawWaitSeconds
  Passed through to New-ViceScreenshot.ps1 for each emulator - see its help
  for details. Default 300.

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

$screenshotScript = Join-Path $PSScriptRoot "New-ViceScreenshot.ps1"
if (-not (Test-Path $screenshotScript)) {
    throw "New-ViceScreenshot.ps1 not found next to this script: $screenshotScript"
}
# run in a fresh process per emulator (rather than dot-sourcing/calling
# in-process) - each capture gets its own GDI+ heap and handle table instead
# of sharing one across all four captures, which a run of the old in-process
# version hit an unexplained "Bitmap.Clone: Out of memory" on 3 separate
# times, always after 1-3 prior captures had already succeeded in the same
# process and never on the same emulator twice - consistent with accumulated
# per-process GDI+ state, not anything specific to one emulator's content.
$pwshExe = (Get-Process -Id $PID).Path

Add-Type -AssemblyName System.Drawing

# top-left, top-right, bottom-left, bottom-right
$emus = @("x128", "x64sc", "xvic", "xplus4")

$workDir = Join-Path $env:TEMP ("vice_meet_bg_" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $workDir | Out-Null

try {
    $shots = [ordered]@{}
    foreach ($emu in $emus) {
        $outFile = Join-Path $workDir "$emu.png"
        $scriptArgs = @(
            "-NoProfile", "-File", $screenshotScript,
            "-ViceBaseFolder", $ViceBaseFolder,
            "-Emulator", $emu,
            "-OutputFile", $outFile,
            "-BasicFilesRoot", $BasicFilesRoot,
            "-CaptureDelaySeconds", $CaptureDelaySeconds,
            "-MaxDrawWaitSeconds", $MaxDrawWaitSeconds
        )
        if ($BasicFile) { $scriptArgs += @("-BasicFile", $BasicFile) }

        & $pwshExe @scriptArgs
        if ($LASTEXITCODE -ne 0) {
            throw "New-ViceScreenshot.ps1 failed for $emu (exit code $LASTEXITCODE)"
        }
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
