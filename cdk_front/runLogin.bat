@echo off

REM This script will start npm dev servers for three projects in separate command prompt windows.
REM This run.bat file should be located in C:\Users\GUILHERME\Desktop\code\cdk front

echo Starting cdk_front_app_shell...
start cmd /k "cd /d "%~dp0cdk_front_login" && call run.bat"

echo All projects are attempting to start. Check the new command prompt windows for status.