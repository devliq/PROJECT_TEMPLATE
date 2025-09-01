@echo off
REM Project Entry Script for Windows
REM Automatically enters WSL and sets up the development environment

echo 🚀 Entering Development Environment
echo ====================================

REM Check if WSL is available
wsl -l >nul 2>&1
if errorlevel 1 (
    echo ❌ WSL is not installed or not available
    echo Please run: wsl --install
    pause
    exit /b 1
)

REM Get the current Windows directory and convert to WSL path
for /f "delims=" %%i in ("%CD%") do set "WIN_DIR=%%i"
set "WSL_DIR=%WIN_DIR:\=/%"
set "WSL_DIR=%WSL_DIR::=%"
set "WSL_DIR=/mnt/%WSL_DIR%"

REM Convert drive letter to lowercase for WSL
set "DRIVE=%WSL_DIR:~5,1%"
if "%DRIVE%"=="C" set "DRIVE=c"
if "%DRIVE%"=="D" set "DRIVE=d"
if "%DRIVE%"=="E" set "DRIVE=e"
if "%DRIVE%"=="F" set "DRIVE=f"
if "%DRIVE%"=="G" set "DRIVE=g"
if "%DRIVE%"=="H" set "DRIVE=h"
if "%DRIVE%"=="I" set "DRIVE=i"
if "%DRIVE%"=="J" set "DRIVE=j"
if "%DRIVE%"=="K" set "DRIVE=k"
if "%DRIVE%"=="L" set "DRIVE=l"
if "%DRIVE%"=="M" set "DRIVE=m"
if "%DRIVE%"=="N" set "DRIVE=n"
if "%DRIVE%"=="O" set "DRIVE=o"
if "%DRIVE%"=="P" set "DRIVE=p"
if "%DRIVE%"=="Q" set "DRIVE=q"
if "%DRIVE%"=="R" set "DRIVE=r"
if "%DRIVE%"=="S" set "DRIVE=s"
if "%DRIVE%"=="T" set "DRIVE=t"
if "%DRIVE%"=="U" set "DRIVE=u"
if "%DRIVE%"=="V" set "DRIVE=v"
if "%DRIVE%"=="W" set "DRIVE=w"
if "%DRIVE%"=="X" set "DRIVE=x"
if "%DRIVE%"=="Y" set "DRIVE=y"
if "%DRIVE%"=="Z" set "DRIVE=z"
set "WSL_DIR=/mnt/%DRIVE%%WSL_DIR:~6%"

echo 📁 Project directory: %WIN_DIR%
echo 🐧 WSL directory: %WSL_DIR%

REM Enter WSL and navigate to project directory
echo.
echo 🔄 Entering WSL and setting up environment...
echo.

wsl -d kali-linux -- bash -c "cd '%WSL_DIR%' && echo '🐧 Welcome to WSL (Kali Linux)!' && echo '📁 Successfully entered project directory' && echo '🔧 Environment will load automatically via direnv' && echo '' && echo '💡 Available commands:' && echo '  • ./07_SCRIPT/setup-dev-workspace.sh  - Create development workspace' && echo '  • npm run dev                        - Start development server' && echo '  • npm test                          - Run tests' && echo '  • docker compose up -d              - Start services' && echo '' && echo '🎯 Your development environment is ready!' && echo '' && echo '🔄 Setting up development workspace...' && (if [ -f './07_SCRIPT/setup-dev-workspace.sh' ]; then ./07_SCRIPT/setup-dev-workspace.sh; else echo '⚠️  Workspace setup script not found. Run manually: ./07_SCRIPT/setup-dev-workspace.sh'; fi) && echo '📂 Returning to project directory...' && cd '%WSL_DIR%' && exec bash --rcfile <(echo 'cd '\''%WSL_DIR%'\''; source ~/.bashrc')"

REM If WSL exits, show a message
echo.
echo 💡 To return to this setup later, run: enter-project.bat
echo.

REM If WSL exits, show a message
echo.
echo 💡 To return to this setup later, run: enter-project.bat
echo.