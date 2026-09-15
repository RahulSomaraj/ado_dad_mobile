@echo off
REM Sell flow (CREATE-07) verification. Double-click from File Explorer.
REM Writes everything to tool\sell_verify.log (Claude can read that file).
cd /d "%~dp0.."
set LOG=tool\sell_verify.log
echo === sell verify %DATE% %TIME% === > %LOG%
echo --- flutter pub get --- >> %LOG%
call flutter pub get >> %LOG% 2>&1
echo --- flutter analyze (sell flow + wiring) --- >> %LOG%
call flutter analyze lib/features/sell/flow lib/common/app_routes.dart lib/common/auth_guard.dart lib/common/widgets/scaffold_with_nav_bar.dart test/features/sell_flow >> %LOG% 2>&1
echo analyze exit code: %ERRORLEVEL% >> %LOG%
echo --- flutter test test/features/sell_flow --- >> %LOG%
call flutter test test/features/sell_flow >> %LOG% 2>&1
echo test exit code: %ERRORLEVEL% >> %LOG%
echo === done === >> %LOG%
type %LOG%
pause
