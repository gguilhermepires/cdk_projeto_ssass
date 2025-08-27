@echo off
echo ===============================================
echo Updating all Git submodules
echo ===============================================
echo.

REM Show current submodule status
echo Current submodule status:
git submodule status
echo.

REM Update all submodules to their latest remote commits
echo Fetching latest changes from all submodules...
git submodule update --remote --merge

echo.
echo ===============================================
echo Updated submodule status:
git submodule status
echo ===============================================
echo.

echo Next steps:
echo 1. Review the changes in each submodule
echo 2. Test your application
echo 3. Commit the submodule updates:
echo    git add .
echo    git commit -m "Update submodules to latest versions"
echo.
pause