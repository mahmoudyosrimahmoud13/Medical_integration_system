@echo off
REM HealthHub Flutter app helper for Windows. Run "run.bat help" to see the options.
setlocal
cd /d "%~dp0"
set DEFINE=
if not "%API_BASE_URL%"=="" set DEFINE=--dart-define=API_BASE_URL=%API_BASE_URL%
set CMD=%1
if "%CMD%"=="" set CMD=help

if "%CMD%"=="setup" goto setup
if "%CMD%"=="run" goto run
if "%CMD%"=="web" goto web
if "%CMD%"=="test" goto test
if "%CMD%"=="analyze" goto analyze
if "%CMD%"=="format" goto format
if "%CMD%"=="apk" goto apk
if "%CMD%"=="appbundle" goto appbundle
if "%CMD%"=="build-web" goto buildweb
if "%CMD%"=="icons" goto icons
if "%CMD%"=="clean" goto clean
goto help

:dosetup
echo ^>^> Creating platform folders if missing
call flutter create . --project-name healthhub --org com.healthhub --platforms=android,ios,web,windows,linux,macos >nul
echo ^>^> Applying HealthHub name, bundle id and permissions
call dart run tool/patch_platforms.dart
echo ^>^> Getting packages
call flutter pub get
echo ^>^> Generating app icons
call dart run flutter_launcher_icons >nul
exit /b 0

:ensure
if not exist android call :dosetup
exit /b 0

:setup
call :dosetup
echo ^>^> Setup done. Try: run.bat run
goto end
:run
call :ensure
call flutter run %DEFINE% %2 %3 %4
goto end
:web
call :ensure
call flutter run -d chrome %DEFINE%
goto end
:test
call flutter pub get >nul
call flutter test %2 %3
goto end
:analyze
call flutter pub get >nul
call flutter analyze
goto end
:format
call dart format lib test tool
goto end
:apk
call :ensure
call flutter build apk --release %DEFINE%
echo ^>^> build\app\outputs\flutter-apk\app-release.apk
goto end
:appbundle
call :ensure
call flutter build appbundle --release %DEFINE%
goto end
:buildweb
call :ensure
call flutter build web --release %DEFINE%
echo ^>^> build\web
goto end
:icons
call dart run flutter_launcher_icons
goto end
:clean
call flutter clean
for %%d in (android ios web windows linux macos) do if exist %%d rmdir /s /q %%d
echo ^>^> Removed build output and generated platform folders
goto end

:help
echo Usage: run.bat ^<option^>      (set API_BASE_URL=http://192.168.1.10:8020 to point at your backend)
echo.
echo   setup       create platform folders, apply the HealthHub identity, get packages, make icons
echo   run         run on the connected device or emulator
echo   web         run in Chrome
echo   test        run unit and widget tests
echo   analyze     static checks
echo   format      format the code
echo   apk         build a release Android APK
echo   appbundle   build a release Android App Bundle
echo   build-web   build the web version
echo   icons       regenerate app icons
echo   clean       remove build output and generated platform folders
:end
endlocal
