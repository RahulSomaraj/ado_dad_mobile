@echo off
REM App update prompt verification. Double-click from File Explorer.
REM Writes everything to tool\version_check_verify.log (Claude can read that file).
cd /d "%~dp0.."
set LOG=tool\version_check_verify.log
echo === version check verify %DATE% %TIME% === > %LOG%
echo --- flutter pub get --- >> %LOG%
call flutter pub get >> %LOG% 2>&1
echo --- flutter analyze (touched files) --- >> %LOG%
call flutter analyze lib/main.dart lib/common/version_check_service.dart lib/common/version_check_wrapper.dart lib/common/widgets/update_app_dialog.dart lib/models/app_version_model.dart lib/repositories/version_repo.dart test/common/version_check_service_test.dart >> %LOG% 2>&1
echo analyze exit code: %ERRORLEVEL% >> %LOG%
echo --- flutter test test/common/version_check_service_test.dart --- >> %LOG%
call flutter test test/common/version_check_service_test.dart >> %LOG% 2>&1
echo test exit code: %ERRORLEVEL% >> %LOG%
echo === done === >> %LOG%
type %LOG%
pause
