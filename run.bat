@echo off
REM HealthHub for Windows: sets up and starts everything. Run "run.bat help" for the options.
setlocal EnableDelayedExpansion
cd /d "%~dp0"
set ROOT=%cd%
set RESET=
set TUNNEL=0
set NOAI=0
set KEEP=0

:args
if "%~1"=="" goto argsdone
if /i "%~1"=="help" goto help
if /i "%~1"=="stop" goto stop
if /i "%~1"=="--reset-demo" set RESET=demo
if /i "%~1"=="--reset-empty" set RESET=empty
if /i "%~1"=="--keep" set KEEP=1
if /i "%~1"=="--tunnel" set TUNNEL=1
if /i "%~1"=="--no-ai" set NOAI=1
shift
goto args
:argsdone

where python >nul 2>nul || (echo Python 3.11+ is missing: https://www.python.org/downloads/ & exit /b 1)
where npm >nul 2>nul || (echo Node.js 20+ is missing: https://nodejs.org & exit /b 1)

echo.
echo == Setting up the backend
if not exist Backend\.venv\Scripts\python.exe python -m venv Backend\.venv
Backend\.venv\Scripts\python.exe -m pip install -q -r Backend\requirements.txt
if not exist Backend\.env copy Backend\.env.example Backend\.env >nul

REM What to do with the data: continue, start over with demo data, or start over empty
if exist Backend\healthhub.db if "%RESET%"=="" if "%KEEP%"=="0" (
  echo.
  echo   You have data. What now?
  echo     1  Continue with it          ^(just press Enter^)
  echo     2  Start over with fresh demo data
  echo     3  Start over empty ^(only the admin account^)
  set CHOICE=
  set /p CHOICE=  Choose 1, 2 or 3: 
  if "!CHOICE!"=="2" set RESET=demo
  if "!CHOICE!"=="3" set RESET=empty
)
if not "%RESET%"=="" (
  if not exist backups mkdir backups
  for /f %%t in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HHmmss"') do set STAMP=%%t
  if exist Backend\healthhub.db (
    powershell -NoProfile -Command "Compress-Archive -Force -Path Backend\healthhub.db,Backend\media -DestinationPath backups\healthhub_!STAMP!_before-wipe.zip"
    echo   Backup saved: backups\healthhub_!STAMP!_before-wipe.zip
    del Backend\healthhub.db
  )
)
set FIRST=0
if not exist Backend\healthhub.db set FIRST=1
pushd Backend
.venv\Scripts\python.exe -m alembic upgrade head
REM continuing with demo data: also add anything newer versions of the demo brought (nothing is deleted)
set SEEDARGS=--demo-if-loaded
if "%RESET%"=="demo" set SEEDARGS=--demo
REM a brand new install gets the demo data, unless --reset-empty was chosen
if "%FIRST%"=="1" if not "%RESET%"=="empty" set SEEDARGS=--demo
.venv\Scripts\python.exe -m app.seed %SEEDARGS%
popd

set ML_SERVICE_URL=
if "%NOAI%"=="0" (
  echo.
  echo == Setting up the drug interaction service
  if not exist AI\.venv\Scripts\python.exe python -m venv AI\.venv
  AI\.venv\Scripts\python.exe -m pip install -q -r AI\requirements.txt
  if not exist AI\data\known_pairs.csv.gz AI\.venv\Scripts\python.exe AI\tools\fetch_data.py AI\data
  start "HealthHub AI" /min cmd /c "cd /d %ROOT%\AI && .venv\Scripts\python.exe -m uvicorn ddi_service.main:app --host 127.0.0.1 --port 8001"
  set ML_SERVICE_URL=http://127.0.0.1:8001
)

echo.
echo == Setting up the website
pushd Web
if not exist node_modules call npm install --no-audit --no-fund --loglevel=error
call npx vite build
popd

echo.
echo == Starting HealthHub
start "HealthHub API" /min cmd /c "cd /d %ROOT%\Backend && .venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8020"
start "HealthHub Web" /min cmd /c "cd /d %ROOT%\Web && npx vite preview --host 127.0.0.1 --port 8080 --strictPort"

if "%TUNNEL%"=="1" (
  where cloudflared >nul 2>nul || (
    echo   Installing cloudflared, Cloudflare's tunnel program...
    winget install --id Cloudflare.cloudflared -e --accept-source-agreements --accept-package-agreements
  )
  echo.
  echo == Opening the Cloudflare tunnel. Your public address appears below as https://....trycloudflare.com
  echo    Paste it into the Android app's "Server address" on the login screen.
  start "HealthHub Tunnel" cmd /k "cloudflared tunnel --no-autoupdate --url http://localhost:8080"
)

echo.
echo   HealthHub is running:   http://localhost:8080
echo   API docs:               http://localhost:8020/docs
echo   Demo password = role + @12345, for example doctor@healthhub.local / Doctor@12345
echo   Stop everything with:   run.bat stop
goto end

:stop
taskkill /fi "WINDOWTITLE eq HealthHub*" /t /f >nul 2>nul
echo HealthHub stopped
goto end

:help
echo Usage: run.bat [options]
echo.
echo   (no option)      set up what is missing and start; asks: continue, demo data, or empty
echo   --keep           continue with your data without asking
echo   --reset-demo     back up, delete all data, load the demo data
echo   --reset-empty    back up, delete all data, start empty
echo   --tunnel         also open a free Cloudflare tunnel (a public https address)
echo   --no-ai          don't start the drug interaction service
echo   stop             stop everything
echo.
echo   Backups, status, logs and your own fixed tunnel are in run.sh (Linux, macOS, or Windows with WSL).

:end
endlocal
