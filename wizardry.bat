@echo off
chcp 65001 >nul
cd /d "%~dp0wizardry-cli"
echo === Wizardry CLI Game ===
echo.
perl wizardry.pl
pause