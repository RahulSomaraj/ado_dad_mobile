@echo off
cd /d "%~dp0.."
set LOG=tool\overflow_verify.log
echo === overflow verify %DATE% %TIME% === > %LOG%
call flutter test test/layout >> %LOG% 2>&1
echo test exit code: %ERRORLEVEL% >> %LOG%
echo === done === >> %LOG%
