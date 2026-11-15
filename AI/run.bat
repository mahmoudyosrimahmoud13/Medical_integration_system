@echo off
REM HealthHub AI (drug interactions) helper for Windows. Run "run.bat help" to see the options.
setlocal
cd /d "%~dp0"
set VENV=.venv
set PY=%VENV%\Scripts\python.exe
if "%PORT%"=="" set PORT=8001
set CMD=%1
if "%CMD%"=="" set CMD=help

if "%CMD%"=="setup" goto setup
if "%CMD%"=="setup-model" goto setupmodel
if "%CMD%"=="data" goto data
if "%CMD%"=="dev" goto dev
if "%CMD%"=="start" goto start
if "%CMD%"=="test" goto test
if "%CMD%"=="lint" goto lint
if "%CMD%"=="docker" goto docker
goto help

:needvenv
if not exist "%PY%" call :dosetup
exit /b 0
:needdata
if not exist data\known_pairs.csv.gz "%PY%" tools\fetch_data.py data
exit /b 0
:dosetup
echo ^>^> Creating the Python virtual environment in %VENV%
python -m venv %VENV%
"%PY%" -m pip install -q --upgrade pip
"%PY%" -m pip install -q -r requirements-dev.txt
if not exist .env copy .env.example .env >nul
echo ^>^> Setup done
exit /b 0

:setup
call :dosetup
goto end
:setupmodel
call :needvenv
echo ^>^> Installing PyTorch (CPU) and the model packages, this is a big download
"%PY%" -m pip install torch --index-url https://download.pytorch.org/whl/cpu
"%PY%" -m pip install -r requirements-model.txt
powershell -Command "(Get-Content .env) -replace '^USE_MODEL=.*','USE_MODEL=true' | Set-Content .env"
goto end
:data
call :needvenv
"%PY%" tools\fetch_data.py data
goto end
:dev
call :needvenv
call :needdata
echo ^>^> AI service on http://localhost:%PORT%/docs
"%VENV%\Scripts\uvicorn.exe" ddi_service.main:app --reload --host 0.0.0.0 --port %PORT%
goto end
:start
call :needvenv
call :needdata
"%VENV%\Scripts\uvicorn.exe" ddi_service.main:app --host 0.0.0.0 --port %PORT%
goto end
:test
call :needvenv
"%PY%" -m pytest -q %2 %3
goto end
:lint
call :needvenv
"%VENV%\Scripts\ruff.exe" check ddi_service tests tools
goto end
:docker
docker build -t healthhub-ai . && docker run --rm -p %PORT%:8001 healthhub-ai
goto end
:help
echo Usage: run.bat ^<option^>
echo.
echo   setup        create .venv and install the small service (DrugBank lookup only)
echo   setup-model  also install PyTorch and turn on the MVN-DDI model (big download)
echo   data         download DrugBank's interaction list into data\
echo   dev          start with auto reload on http://localhost:8001
echo   start        start for production
echo   test         run the tests
echo   lint         check the code style
echo   docker       build and run the Docker image
:end
endlocal
