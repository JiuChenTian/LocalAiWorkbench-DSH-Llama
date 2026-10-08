@echo off
setlocal
REM ============================================================
REM  NInfer beta kit -- tier: PTQ1_0 (ternary, 1.75 bpw, MTP-only artifact)
REM  Model : models\bonsai2_27b_ternary_ptq1_native_mtp.ninfer  (5.96 GiB)
REM  Port  : 8095
REM
REM  NOTE  : this artifact carries the text backbone + the MTP head ONLY.
REM          - use --spec mtp              (there is no dflash2 component in it)
REM          - do NOT add --lm-head-draft  (it asks for the proposal head, which
REM            this file does not carry: the engine refuses to start)
REM          - do NOT add --vision         (no vision tower in this file)
REM
REM  PTQ1-SPECIFIC, NOT OPTIONAL:
REM          set "NINFER_TERNARY_PTQ1_FAST=1" below is what puts PTQ1_0's fast
REM          rungs on. With it unset the engine resolves them OFF and every
REM          SINGLE projection (MLP, attention output) falls back to the
REM          per-weight reference rung: measured 44.7 tok/s prefill against
REM          2.2k with the rung on -- a factor of ~50, with no error line and
REM          a correct answer, so it looks like "the model is just slow".
REM          (The I line's own kit ships this switch ON for the same reason.)
REM
REM  ASCII-only on purpose. A .bat is parsed in the OEM/ANSI codepage;
REM  non-ASCII text here corrupts the commands.
REM ============================================================

REM ---- CUDA runtime: shipped inside engine\ (no toolkit needed) ----
set "CUDA_BIN=%~dp0engine"
set "PATH=%CUDA_BIN%;%CUDA_BIN%\x64;%PATH%"

REM ---- pick the engine that matches THIS card (one binary per architecture) ----
REM  An sm_89 cubin carries no PTX for sm_120 and vice versa, so the wrong
REM  engine does not fall back -- it dies with no usable kernel image.
call "%~dp0engine\pick-engine.bat"
if errorlevel 1 (
  pause
  exit /b %ERRORLEVEL%
)

REM ---- KVMem ring + host-backed prefix reuse: ALL FIVE matter ------
REM  With only WINDOW + REUSE set, the tier starts and reports ~99.9% cache
REM  but ANSWERS WRONG on long prompts: the middle of the context becomes
REM  invisible, with zero error lines. RETRIEVE is what brings it back.
set "NINFER_KV_WINDOW=16384"
set "NINFER_KV_RETRIEVE=8192"
set "NINFER_KV_RING=1"
set "NINFER_HOST_PAGEABLE=1"
set "NINFER_KV_REUSE_HOSTBACKED=1"

REM ---- PTQ1_0 rung switch: see the header note (do not remove) ----
set "NINFER_TERNARY_PTQ1_FAST=1"

cd /d "%~dp0engine"

echo.
echo   Tier  : PTQ1_0 (ternary 1.75 bpw, MTP-only) - ring + host-backed reuse
echo   Model : %~dp0models\bonsai2_27b_ternary_ptq1_native_mtp.ninfer
echo   URL   : http://127.0.0.1:8095
echo   Ready : curl.exe -s -o NUL -w "%%{http_code}" http://127.0.0.1:8095/v1/models   (expect 200)
echo   Note  : --max-shared-prefixes 0 is REQUIRED
echo   Note  : MTP-only tier - do NOT add --lm-head-draft or --vision
echo   Note  : PTQ1_0 fast rungs are ON (NINFER_TERNARY_PTQ1_FAST=1)
echo.

"%ENGINE%" "%~dp0models\bonsai2_27b_ternary_ptq1_native_mtp.ninfer" ^
  --host 127.0.0.1 --port 8095 --model-id qwen3.8-27b ^
  --max-context 262144 --kv-capacity 17920 --kv-dtype k8v4 --host-kv-mib 16384 ^
  --prefill-chunk 1024 --spec mtp --draft-tokens 4 ^
  --default-max-tokens 32768 --default-reasoning-effort none --max-concurrency 1 ^
  --max-shared-prefixes 0 ^
  --presence-penalty 0 --temperature 0.7 --top-p 0.9 --top-k 20

echo.
echo [engine exited] errorlevel=%ERRORLEVEL%
pause
