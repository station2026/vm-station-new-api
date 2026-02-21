@echo off
setlocal enabledelayedexpansion

:: ===================================================================
::  update.bat - HTTP API URL Updater
::
::  This script pulls the latest ngrok HTTP URL from Git and
::  saves it to a local config file for easy access.
:: ===================================================================

set "LOG_FILE=%USERPROFILE%\.vm-station-new-api\connected_info.log"
set "CONFIG_FILE=%USERPROFILE%\.vm-station-new-api\api_url.txt"

echo ===================================================================
echo  VM Station New API - HTTP URL Update Script
echo ===================================================================
echo.

echo INFO: Pulling latest connection info from Git...
cd %USERPROFILE%\.vm-station-new-api
git pull
if %ERRORLEVEL% neq 0 (
    echo WARNING: Git pull failed. Using existing local file.
)
echo.

echo INFO: Checking for log file at %LOG_FILE%...
if not exist "%LOG_FILE%" (
    echo ERROR: The log file was not found!
    goto :ERROR_AND_PAUSE
)
for %%A in ("%LOG_FILE%") do set "FILE_SIZE=%%~zA"
if %FILE_SIZE%==0 (
    echo ERROR: The log file is empty.
    goto :ERROR_AND_PAUSE
)
echo SUCCESS: Log file found and is not empty.
echo.

echo INFO: Reading HTTP API URL...
set /p API_URL=<%LOG_FILE%

if not defined API_URL (
    echo ERROR: Could not read the API URL.
    goto :ERROR_AND_PAUSE
)

echo SUCCESS: API URL retrieved:
echo.
echo   %API_URL%
echo.

:: Save the URL to a config file for easy reference
echo %API_URL% > "%CONFIG_FILE%"
echo INFO: URL saved to %CONFIG_FILE%
echo.

:: Copy to clipboard if clip.exe is available
echo %API_URL% | clip 2>nul
if %ERRORLEVEL% equ 0 (
    echo SUCCESS: URL copied to clipboard!
) else (
    echo INFO: Clipboard copy not available.
)
echo.

:: Update Claude settings.json
echo INFO: Updating Claude settings...
set "CLAUDE_DIR=%USERPROFILE%\.claude"
set "CLAUDE_SETTINGS=%CLAUDE_DIR%\settings.json"

:: Create .claude directory if it doesn't exist
if not exist "%CLAUDE_DIR%" (
    mkdir "%CLAUDE_DIR%"
    echo INFO: Created .claude directory
)

:: Check if settings.json exists
if not exist "%CLAUDE_SETTINGS%" (
    echo INFO: settings.json not found, creating new file...
    (
        echo {
        echo   "env": {
        echo     "ANTHROPIC_API_KEY": "your-api-key",
        echo     "ANTHROPIC_BASE_URL": "%API_URL%",
        echo     "API_TIMEOUT_MS": "3000000",
        echo     "ANTHROPIC_DEFAULT_SONNET_MODEL": "gemini-claude-sonnet-4-5-thinking",
        echo     "ANTHROPIC_DEFAULT_OPUS_MODEL": "gemini-claude-opus-4-5-thinking",
        echo     "ANTHROPIC_DEFAULT_HAIKU_MODEL": "gemini-claude-sonnet-4-5",
        echo     "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "0",
        echo     "NODE_TLS_REJECT_UNAUTHORIZED": "0"
        echo   },
        echo   "autoUpdaterStatus": "disabled",
        echo   "model": "sonnet"
        echo }
    ) > "%CLAUDE_SETTINGS%"
    echo SUCCESS: Created settings.json with API URL: %API_URL%
) else (
    echo INFO: Updating existing settings.json...
    powershell -NoProfile -Command "$jsonPath='%CLAUDE_SETTINGS%'; $newUrl='%API_URL%'; try { $json = Get-Content $jsonPath -Raw | ConvertFrom-Json; $json.env.ANTHROPIC_BASE_URL = $newUrl; $json | ConvertTo-Json -Depth 10 | Set-Content $jsonPath -Encoding UTF8; Write-Host 'SUCCESS: Updated ANTHROPIC_BASE_URL to:' $newUrl } catch { Write-Host 'ERROR: Failed to update settings.json:' $_.Exception.Message; exit 1 }"
    if %ERRORLEVEL% neq 0 (
        echo WARNING: PowerShell update failed, trying text replacement...
        call :UPDATE_JSON_FALLBACK
    )
)
echo.

goto :SUCCESS

:UPDATE_JSON_FALLBACK
:: Fallback method using text replacement
set "TEMP_SETTINGS=%TEMP%\claude_settings_%RANDOM%.tmp"
set "FOUND_LINE=0"
(
    for /f "usebackq tokens=* delims=" %%L in ("%CLAUDE_SETTINGS%") do (
        set "line=%%L"
        echo !line! | findstr /C:"ANTHROPIC_BASE_URL" >nul
        if !ERRORLEVEL! equ 0 (
            echo     "ANTHROPIC_BASE_URL": "%API_URL%",
            set "FOUND_LINE=1"
        ) else (
            echo !line!
        )
    )
) > "%TEMP_SETTINGS%"

if "!FOUND_LINE!"=="1" (
    move /Y "%TEMP_SETTINGS%" "%CLAUDE_SETTINGS%" >nul
    echo SUCCESS: Updated ANTHROPIC_BASE_URL using fallback method
) else (
    del "%TEMP_SETTINGS%" 2>nul
    echo WARNING: Could not find ANTHROPIC_BASE_URL line in settings.json
)
exit /b 0

:SUCCESS
echo ===================================================================
echo.
echo  SUCCESS: Script finished!
echo.
echo  API URL: %API_URL%
echo.
echo  You can now use this URL to access your HTTP API.
echo.
goto :END

:ERROR_AND_PAUSE
echo.
echo ===================================================================
echo.
echo  AN ERROR OCCURRED. Please review the messages above.
echo.
pause

:END
exit /b 0
