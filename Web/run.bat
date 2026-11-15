@echo off
REM HealthHub web app helper for Windows. Run "run.bat help" to see the options.
setlocal
cd /d "%~dp0"

set CMD=%1
if "%CMD%"=="" set CMD=help

if "%CMD%"=="setup" goto setup
if "%CMD%"=="dev" goto dev
if "%CMD%"=="full" goto full
if "%CMD%"=="test" goto test
if "%CMD%"=="watch" goto watch
if "%CMD%"=="check" goto check
if "%CMD%"=="build" goto build
if "%CMD%"=="preview" goto preview
if "%CMD%"=="docker" goto docker
if "%CMD%"=="clean" goto clean
goto help

:needmodules
if not exist node_modules call :dosetup
exit /b 0

:dosetup
where npm >nul 2>nul || (echo !! Node.js 20 or newer is needed: https://nodejs.org & exit /b 1)
echo ^>^> Installing packages
call npm install
if not exist .env copy .env.example .env >nul
echo ^>^> Setup done
exit /b 0

:setup
call :dosetup
goto end

:dev
call :needmodules
echo ^>^> Web app on http://localhost:5173
call npx vite --host
goto end

:full
call :needmodules
if exist ..\Backend\run.bat (
  echo ^>^> Starting the API in a new window
  start "HealthHub API" cmd /k "..\Backend\run.bat dev"
  timeout /t 5 >nul
)
call npx vite --host
goto end

:test
call :needmodules
call npx vitest run %2 %3
goto end

:watch
call :needmodules
call npx vitest
goto end

:check
call :needmodules
call npx tsc -b --noEmit
goto end

:build
call :needmodules
call npm run build
goto end

:preview
call :needmodules
call npm run build
call npx vite preview --host --port 4173
goto end

:docker
echo ^>^> Starting database + API + web with Docker on http://localhost:8080
docker compose -f ..\docker-compose.yml up --build
goto end

:clean
if exist node_modules rmdir /s /q node_modules
if exist dist rmdir /s /q dist
echo ^>^> Removed node_modules and dist
goto end

:help
echo Usage: run.bat ^<option^>
echo.
echo   setup     install packages and create .env
echo   dev       start the web app with live reload on http://localhost:5173
echo   full      start the API (..\Backend) and the web app together
echo   test      run the tests once
echo   watch     run the tests again on every save
echo   check     check TypeScript types
echo   build     build the production files into dist\
echo   preview   build, then serve dist\ on http://localhost:4173
echo   docker    run database + API + web in Docker on http://localhost:8080
echo   clean     delete node_modules and dist

:end
endlocal
