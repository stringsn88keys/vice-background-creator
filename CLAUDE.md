# Repo notes for Claude

## Commented companions for BASIC listings

Every listing under `basic-files/**/*.bas` gets a sibling `{name}-commented.bas`
in the same directory (e.g. `sine.bas` -> `sine-commented.bas`). Keep it in
sync whenever the original changes:

- Same code, unchanged, at the same line numbers.
- Before each code line, insert a `REM` line explaining what it does, numbered
  `{that line's number} - 1` (code at `150` gets its `REM` at `149`).
- If two consecutive code lines are numbered less than 2 apart (no room for
  the `-1` line), renumber the later ones to open a gap first - check that
  nothing (`GOTO`/`GOSUB`/`THEN`) jumps to the line number you're moving
  before renumbering it.
- Comments explain *purpose*, not syntax - what the line accomplishes in the
  program, not a restatement of the BASIC keywords already on it.

The commented copy is a reference/readability artifact, not the one to prefer
for `-BasicFile` autostart - the extra `REM` lines roughly double program
size, which matters on the VIC-20's tight unexpanded memory. If it's needed
there, `New-ViceScreenshot.ps1` passes VICE's `-memory 3k` automatically for
any `xvic` run whose `-BasicFile` matches `*-commented.bas`.
