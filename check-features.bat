@echo off
setlocal enabledelayedexpansion

:: Set the features directory path
set "FEATURES_DIR=C:\Users\GUILHERME\Desktop\code\projeto ssass\.claude\commands\features"
set "PROCESSED_DIR=C:\Users\GUILHERME\Desktop\code\projeto ssass\.claude\commands\processed"

:: Create processed directory if it doesn't exist
if not exist "%PROCESSED_DIR%" (
    mkdir "%PROCESSED_DIR%"
)

:: Check if the features directory exists
if not exist "%FEATURES_DIR%" (
    echo Features directory does not exist: %FEATURES_DIR%
    pause
    exit /b 1
)

echo Starting feature file monitoring loop...
echo Press Ctrl+C to stop
echo.

:loop
    :: Check for new files in the features directory
    set "NEW_FILES_FOUND="
    
    for %%f in ("%FEATURES_DIR%\*.md") do (
        set "FILENAME=%%~nxf"
        set "FULL_PATH=%%f"
        
        :: Check if this file has already been processed
        if not exist "%PROCESSED_DIR%\!FILENAME!" (
            echo [%date% %time%] Found new task file: !FILENAME!
            
            :: Call Claude with tech-lead-orchestrator agent
            call :process_file "!FULL_PATH!" "!FILENAME!"
            
            :: Mark file as processed by creating a marker file
            echo Processed on %date% %time% > "%PROCESSED_DIR%\!FILENAME!"
            
            set "NEW_FILES_FOUND=1"
        )
    )
    
    if not defined NEW_FILES_FOUND (
        echo [%date% %time%] No new files found, waiting...
    )
    
    :: Wait 5 seconds before checking again
    timeout /t 5 /nobreak > nul
    
    goto :loop

:process_file
    set "FILE_PATH=%~1"
    set "FILE_NAME=%~2"
    
    echo.
    echo ==========================================
    echo Processing: %FILE_NAME%
    echo ==========================================
    echo.
    
    :: Use PowerShell to read the file content and call Claude
    powershell -Command "& {
        $filePath = '%FILE_PATH%'
        $fileName = '%FILE_NAME%'
        
        try {
            $content = Get-Content -Path $filePath -Raw -Encoding UTF8
            Write-Host 'File content loaded successfully' -ForegroundColor Green
            
            # Prepare the prompt for the tech-lead-orchestrator agent
            $prompt = 'Please process this task specification and coordinate the complete development lifecycle: `n`n' + $content
            
            Write-Host 'Calling Claude with tech-lead-orchestrator agent...' -ForegroundColor Yellow
            
            # Call Claude CLI with the agent
            & claude --agent tech-lead-orchestrator $prompt
            
            Write-Host 'Successfully processed: ' + $fileName -ForegroundColor Green
            
        } catch {
            Write-Host 'Error processing file: ' + $fileName -ForegroundColor Red
            Write-Host 'Error details: ' + $_.Exception.Message -ForegroundColor Red
            Write-Host 'Please ensure Claude CLI is installed and in PATH' -ForegroundColor Yellow
        }
    }"
    
    echo.
    echo ==========================================
    echo Completed processing: %FILE_NAME%
    echo ==========================================
    echo.
    
    goto :eof

:: Handle Ctrl+C gracefully
:cleanup
echo.
echo Script terminated by user.
pause
exit /b 0