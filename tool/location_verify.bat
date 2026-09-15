@echo off
REM Location refactor verification. Double-click from File Explorer.
REM Writes everything to tool\location_verify.log (Claude can read that file).
cd /d "%~dp0.."
set LOG=tool\location_verify.log
echo === location verify %DATE% %TIME% === > %LOG%
echo --- flutter pub get --- >> %LOG%
call flutter pub get >> %LOG% 2>&1
echo --- flutter analyze (touched files) --- >> %LOG%
call flutter analyze lib/services lib/main.dart lib/features/home/ui/home_page.dart lib/features/home/ui/category_list_page.dart lib/features/home/ui/widgets lib/repositories/add_repo.dart lib/features/home/ui/ad_detail/ad_detail_seller.dart test/services >> %LOG% 2>&1
echo analyze exit code: %ERRORLEVEL% >> %LOG%
echo --- flutter test test/services/location --- >> %LOG%
call flutter test test/services/location >> %LOG% 2>&1
echo test exit code: %ERRORLEVEL% >> %LOG%
echo === done === >> %LOG%
type %LOG%
pause
