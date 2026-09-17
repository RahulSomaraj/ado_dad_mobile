@echo off
REM Audit fix batch (4.1-4.5, 3.3, prod API). Double-click from File Explorer.
REM Writes everything to tool\audit_fix_verify.log (Claude reads that file).
cd /d "%~dp0.."
set LOG=tool\audit_fix_verify.log
echo === audit fix verify %DATE% %TIME% === > %LOG%
echo --- flutter pub get --- >> %LOG%
call flutter pub get >> %LOG% 2>&1
echo pub get exit code: %ERRORLEVEL% >> %LOG%
echo --- flutter analyze lib test --- >> %LOG%
call flutter analyze lib test >> %LOG% 2>&1
echo analyze exit code: %ERRORLEVEL% >> %LOG%
echo --- flutter test --- >> %LOG%
call flutter test --reporter expanded test/features/sell_flow test/features/home test/common test/services test/layout test/features/chat >> %LOG% 2>&1
echo test exit code: %ERRORLEVEL% >> %LOG%
echo === done === >> %LOG%
type %LOG%
pause
