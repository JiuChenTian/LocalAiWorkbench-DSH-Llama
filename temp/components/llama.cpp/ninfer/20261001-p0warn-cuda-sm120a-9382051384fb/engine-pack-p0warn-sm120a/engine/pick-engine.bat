@echo off
REM ============================================================
REM  pick-engine.bat -- choose the engine that matches THIS card.
REM
REM  Called by the start-*.bat launchers:  call "%~dp0engine\pick-engine.bat"
REM  On success it leaves %ENGINE% set to the full path of the right binary
REM  (that is what the "endlocal & set" at the bottom is for).
REM
REM  Origin: our own arch-selection case, E:\infer-build\archsel\verify120.sel.bat
REM  (2026-09), extended from two architectures to three.
REM
REM  Why one binary per architecture -- the comment from that case, verbatim:
REM    "Arch-specific binaries; neither carries PTX for the other arch, so the wrong
REM     one does NOT fall back -- it dies or wedges with no usable kernel image."
REM
REM  Exit codes:  0 = picked    3 = cannot read the card    4 = card known, its
REM               binary is missing    5 = architecture not shipped
REM
REM  ASCII-only on purpose: cmd parses a .bat in the OEM/ANSI codepage.
REM
REM  ---------------------------------------------------------------------------
REM  FIX 2026-10-01 (all-card-types launcher bug). The donor one-liner was:
REM      for /f "tokens=1 delims=," %%C in ('nvidia-smi --query-gpu^=compute_cap --format^=csv,noheader 2^>NUL') do ...
REM  In that command string `=` was escaped but the COMMA was not, so cmd split the
REM  command at the comma and handed nvidia-smi a stray `noheader` argument. It then
REM  printed "ERROR: Option noheader is not recognized ..." and the for /f passed THAT
REM  TEXT to the selector as if it were a compute capability -- so a fully supported
REM  card was rejected with exit 5 and every start-*.bat died before the engine ran.
REM  Measured on the build box (RTX 4080 SUPER = cc 8.9, supported): the plain command
REM  prints 8.9, the for /f form does not. Reported by 3 independent testers.
REM
REM  Fix, two parts, and BOTH are needed:
REM    1) do not put the query inside a `for /f` command string at all -- run it as an
REM       ordinary statement and read the file (nothing left for cmd to split);
REM    2) GUARD: an unrecognised reading must never become a card id. A reading that
REM       is not a `major.minor` pair is discarded, and the caller sees exit 3 with
REM       the reason, instead of a supported card being blamed for "unknown arch".
REM  Part 2 is the part that matters: it is what turns a silent wrong answer into a
REM  loud refusal, and it is the only part that survives the NEXT quoting surprise.
REM  ---------------------------------------------------------------------------
setlocal
set "ENGINE="
set "CAP="

REM NINFER_AGENT_CC overrides the reading; it exists so the selection can be
REM tested on a machine whose card is not the one being simulated.
if defined NINFER_AGENT_CC set "CAP=%NINFER_AGENT_CC%"
if not defined CAP set "CCFILE=%TEMP%\ninfer-compute-cap.txt"
if not defined CAP nvidia-smi --query-gpu=compute_cap --format=csv,noheader > "%CCFILE%" 2>NUL
if not defined CAP if exist "%CCFILE%" set /p CAP=<"%CCFILE%"
if defined CCFILE del "%CCFILE%" >NUL 2>NUL

REM GUARD (part 2 above): keep only a bare major.minor. Anything else -- nvidia-smi's
REM own error text, an empty file, a driver stub, a locale-mangled number -- is dropped
REM so the exit-5 branch below can never be reached by a value we did not understand.
if defined CAP echo %CAP%| findstr /r /c:"^[0-9][0-9]*\.[0-9][0-9]*$" >NUL || set "CAP="

if not defined CAP (
  echo [ERROR] could not read the GPU compute capability ^(nvidia-smi^).
  echo         Install the NVIDIA driver, or set NINFER_AGENT_CC yourself.
  echo         A reading that is not a major.minor pair is refused rather than
  echo         guessed at, so a supported card is never reported as unsupported.
  echo         See docs\02-*.md ^(troubleshooting^).
  endlocal & exit /b 3
)

set "HERE=%~dp0"
if "%CAP%"=="8.6"  set "ENGINE=%HERE%ninfer-serve-86.exe"
if "%CAP%"=="8.9"  set "ENGINE=%HERE%ninfer-serve-89.exe"
if "%CAP%"=="12.0" set "ENGINE=%HERE%ninfer-serve-120a.exe"

if not defined ENGINE (
  echo [ERROR] this kit ships engines for 8.6 ^(RTX 30^), 8.9 ^(RTX 40^) and 12.0 ^(RTX 50^) only.
  echo         Your card reports compute capability %CAP%.
  echo         See docs\11-*.md ^(per-card differences^).
  endlocal & exit /b 5
)

if not exist "%ENGINE%" (
  echo [ERROR] your card is compute capability %CAP% but this engine is missing:
  echo           %ENGINE%
  echo         Put the engine for your architecture into engine\ and run again.
  endlocal & exit /b 4
)

echo   Card   : compute capability %CAP%
echo   Engine : %ENGINE%
endlocal & set "ENGINE=%ENGINE%"
exit /b 0
