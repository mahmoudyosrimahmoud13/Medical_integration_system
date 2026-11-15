@echo off
REM HealthHub backend helper for Windows. Run "run.bat help" to see the options.
setlocal
cd /d "%~dp0"

set VENV=.venv
set PY=%VENV%\Scripts\python.exe
if "%PORT%"=="" set PORT=8000

set CMD=%1
if "%CMD%"=="" set CMD=help

if "%CMD%"=="setup" goto setup
if "%CMD%"=="dev" goto dev
if "%CMD%"=="start" goto start
if "%CMD%"=="migrate" goto migrate
if "%CMD%"=="seed" goto seed
if "%CMD%"=="test" goto test
if "%CMD%"=="lint" goto lint
if "%CMD%"=="reset" goto reset
if "%CMD%"=="docker" goto docker
if "%CMD%"=="docker-down" goto dockerdown
goto help

:needvenv
if not exist "%PY%" call :dosetup
exit /b 0

:dosetup
echo ^>^> Creating the Python virtual environment in %VENV%
python -m venv %VENV%
"%PY%" -m pip install --upgrade pip -q
echo ^>^> Installing packages
"%PY%" -m pip install -r requirements-dev.txt -q
if not exist .env copy .env.example .env >nul
echo ^>^> Setup done
exit /b 0

:setup
call :dosetup
goto end

:domigrate
echo ^>^> Updating the database tables
"%VENV%\Scripts\alembic.exe" upgrade head
exit /b 0

:migrate
call :needvenv
call :domigrate
goto end

:seed
call :needvenv
"%PY%" -m app.seed %2
goto end

:dev
call :needvenv
call :domigrate
"%PY%" -m app.seed --demo
echo ^>^> API on http://localhost:%PORT%   docs on http://localhost:%PORT%/docs
"%VENV%\Scripts\uvicorn.exe" app.main:app --reload --host 0.0.0.0 --port %PORT%
goto end

:start
call :needvenv
call :domigrate
"%PY%" -m app.seed
"%VENV%\Scripts\uvicorn.exe" app.main:app --host 0.0.0.0 --port %PORT% --workers 2
goto end

:test
call :needvenv
"%PY%" -m pytest -q
goto end

:lint
call :needvenv
"%VENV%\Scripts\ruff.exe" check app tests
goto end

:reset
call :needvenv
if exist healthhub.db del healthhub.db
call :domigrate
"%PY%" -m app.seed --demo
goto end

:docker
docker compose up --build -d
echo ^>^> API on http://localhost:8000/docs
goto end

:dockerdown
docker compose down
goto end

:help
echo Usage: run.bat ^<option^>
echo.
echo   setup         create .venv, install packages, create .env
echo   dev           migrate + demo data + start with auto reload (set PORT=8000)
echo   start         migrate + reference data + start for production
echo   migrate       create or update the database tables
echo   seed [--demo] load governorates, areas, specialties, drugs, admin (+ demo users)
echo   test          run the test suite
echo   lint          check the code style
echo   reset         delete the local SQLite database and rebuild it with demo data
echo   docker        start PostgreSQL + API with Docker Compose
echo   docker-down   stop the Docker containers

:end
endlocal
