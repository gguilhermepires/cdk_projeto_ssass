@echo off
setlocal enabledelayedexpansion

:: Set the features directory path
set "FEATURES_DIR=C:\Users\GUILHERME\Desktop\code\projeto ssass\.claude\commands\features"
set "PROCESSED_DIR=C:\Users\GUILHERME\Desktop\code\projeto ssass\.claude\commands\processed"

:: Create processed directory if it doesn't exist
if not exist "%PROCESSED_DIR%" (
    mkdir "%PROCESSED_DIR%"
    echo Created processed directory: %PROCESSED_DIR%
)

:: Check if the features directory exists
if not exist "%FEATURES_DIR%" (
    echo Features directory does not exist: %FEATURES_DIR%
    pause
    exit /b 1
)

echo Starting feature file monitoring loop...
echo Checking directory: %FEATURES_DIR%
echo Press Ctrl+C to stop
echo.

:loop
    :: Check for new files in the features directory
    set "NEW_FILES_FOUND="
    set "FILE_COUNT=0"
    
    for %%f in ("%FEATURES_DIR%\*.md") do (
        set /a FILE_COUNT+=1
        set "FILENAME=%%~nxf"
        set "FULL_PATH=%%f"
        
        :: Check if this file has already been processed
        if not exist "%PROCESSED_DIR%\!FILENAME!" (
            echo [%date% %time%] Found new task file: !FILENAME!
            
            :: Call the processing function
            call :process_file "!FULL_PATH!" "!FILENAME!"
            
            :: Mark file as processed by creating a marker file
            echo Processed on %date% %time% > "%PROCESSED_DIR%\!FILENAME!"
            echo File marked as processed: !FILENAME!
            
            set "NEW_FILES_FOUND=1"
        )
    )
    
    if not defined NEW_FILES_FOUND (
        if %FILE_COUNT% equ 0 (
            echo [%date% %time%] No .md files found in features directory
        ) else (
            echo [%date% %time%] All %FILE_COUNT% files already processed, waiting...
        )
    )
    
    :: Wait 5 seconds before checking again (Windows timeout command)
    ping localhost -n 6 > nul 2>&1
    
    goto :loop

:process_file
    set "FILE_PATH=%~1"
    set "FILE_NAME=%~2"
    
    echo.
    echo ==========================================
    echo Processing: %FILE_NAME%
    echo File Path: %FILE_PATH%
    echo ==========================================
    echo.
    
    :: Check if already processed (double-check)
    if exist "%PROCESSED_DIR%\%FILE_NAME%" (
        echo WARNING: File %FILE_NAME% already marked as processed, skipping...
        goto :eof
    )
    
    :: Read the task content
    echo Reading task specification...
    
    :: Display preview of the task
    echo ==== TASK PREVIEW ====
    powershell -Command "Get-Content '%FILE_PATH%' | Select-Object -First 5"
    echo ... [task specification continues]
    echo.
    
    :: Create the prompt for the tech-lead-orchestrator
    echo Preparing to call tech-lead-orchestrator agent...
    
    :: Use PowerShell to call Claude Code via stdin (simulating user input)
    echo Calling tech-lead-orchestrator agent through Claude Code interface...
    
    powershell -Command ^
        "$content = Get-Content -Path '%FILE_PATH%' -Raw -Encoding UTF8; " ^
        "$prompt = 'Please coordinate the complete development lifecycle for this task specification using your tech-lead-orchestrator capabilities: ' + $content; " ^
        "Write-Host 'Task content prepared for tech-lead-orchestrator agent' -ForegroundColor Green; " ^
        "Write-Host 'File: %FILE_NAME%' -ForegroundColor Yellow; " ^
        "Write-Host 'Content length:' ($content.Length) 'characters' -ForegroundColor Cyan; " ^
        "Write-Host 'Agent: tech-lead-orchestrator' -ForegroundColor Magenta; " ^
        "Write-Host '' ; " ^
        "Write-Host '=== AGENT CALL SIMULATION ===' -ForegroundColor Red; " ^
        "Write-Host 'This would call the tech-lead-orchestrator agent with the task specification' -ForegroundColor Red; " ^
        "Write-Host 'In a real implementation, this would invoke Claude Code with the agent' -ForegroundColor Red"
    
    echo.
    echo ==========================================
    echo Successfully processed: %FILE_NAME%
    echo ==========================================
    echo.
    
    goto :eof

:: Handle Ctrl+C gracefully  
:cleanup
echo.
echo Script terminated by user.
pause
exit /b 0