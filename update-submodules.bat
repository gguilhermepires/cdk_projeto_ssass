@echo off
echo Updating all submodules...

REM Update all submodules to their latest commits
git submodule update --remote --merge

REM Alternative: Update and pull latest from each submodule's default branch
REM git submodule foreach git pull origin main

echo.
echo Submodules updated successfully!
echo.
echo Don't forget to commit the submodule updates:
echo   git add .
echo   git commit -m "Update submodules"
echo.
pause