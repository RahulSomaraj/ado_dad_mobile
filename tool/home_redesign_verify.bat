@echo off
REM Home hero redesign check. Double-click from File Explorer.
REM Writes everything to tool\home_redesign_verify.log (Claude reads that file).
cd /d "%~dp0.."
set LOG=tool\home_redesign_verify.log
echo === home redesign verify %DATE% %TIME% === > %LOG%
echo --- flutter pub get --- >> %LOG%
call flutter pub get >> %LOG% 2>&1
echo pub get exit code: %ERRORLEVEL% >> %LOG%
echo --- flutter analyze lib --- >> %LOG%
call flutter analyze lib >> %LOG% 2>&1
echo analyze exit code: %ERRORLEVEL% >> %LOG%
echo --- flutter test test/layout --- >> %LOG%
call flutter test test/layout >> %LOG% 2>&1
echo test exit code: %ERRORLEVEL% >> %LOG%
echo === done === >> %LOG%
type %LOG%
pause
