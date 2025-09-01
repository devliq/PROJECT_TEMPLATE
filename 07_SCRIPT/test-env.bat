@echo off
REM =============================================================================
REM WINDOWS BATCH FILE TO RUN ENVIRONMENT TEST
REM =============================================================================
REM This batch file runs the environment test script with multiple shell support

echo 🧪 Running Environment Test...
echo.

REM Set log file
set LOG_FILE=%~dp0test-env.log
echo [%DATE% %TIME%] Starting environment test >> "%LOG_FILE%"

REM Check for available shells in order of preference
set SHELL_FOUND=0
set SHELL_CMD=

REM Check for bash
where bash >nul 2>nul
if %ERRORLEVEL% equ 0 (
    set SHELL_CMD=bash
    set SHELL_FOUND=1
    echo ✅ Bash found, using bash >> "%LOG_FILE%"
) else (
    REM Check for PowerShell
    where powershell >nul 2>nul
    if %ERRORLEVEL% equ 0 (
        set SHELL_CMD=powershell -ExecutionPolicy Bypass -File
        set SHELL_FOUND=1
        echo ✅ PowerShell found, using PowerShell >> "%LOG_FILE%"
    ) else (
        REM Fallback to cmd
        set SHELL_CMD=cmd /c
        set SHELL_FOUND=1
        echo ✅ Using cmd as fallback >> "%LOG_FILE%"
    )
)

if %SHELL_FOUND% equ 0 (
    echo ❌ No suitable shell found. Please install bash or PowerShell.
    echo [%DATE% %TIME%] No shell found >> "%LOG_FILE%"
    pause
    exit /b 1
)

REM Check if test-env.sh exists
if not exist "%~dp0test-env.sh" (
    echo ⚠️  test-env.sh not found. Attempting to create basic test script...
    echo [%DATE% %TIME%] test-env.sh not found, creating basic script >> "%LOG_FILE%"
    (
        echo #!/bin/bash
        echo echo "🧪 Basic Environment Test"
        echo echo "Node.js version: $(node --version 2>/dev/null || echo 'Not installed')"
        echo echo "NPM version: $(npm --version 2>/dev/null || echo 'Not installed')"
        echo echo "Python version: $(python --version 2>/dev/null || echo 'Not installed')"
        echo echo "✅ Test completed"
    ) > "%~dp0test-env.sh"
    echo ✅ Created basic test-env.sh
)

REM Run the test script
echo Running test with %SHELL_CMD%...
%SHELL_CMD% "%~dp0test-env.sh" >> "%LOG_FILE%" 2>&1
set TEST_RESULT=%ERRORLEVEL%

REM Display results and log
echo.
echo 📋 Test Results:
type "%LOG_FILE%" | findstr /v "^\["
echo.
echo 📄 Full log saved to: %LOG_FILE%
echo.

if %TEST_RESULT% equ 0 (
    echo ✅ Environment test completed successfully
    echo [%DATE% %TIME%] Test completed successfully >> "%LOG_FILE%"
) else (
    echo ❌ Environment test failed with error code %TEST_RESULT%
    echo [%DATE% %TIME%] Test failed with error code %TEST_RESULT% >> "%LOG_FILE%"
)

echo.
echo Press any key to exit...
pause >nul