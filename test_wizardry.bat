@echo off
chcp 65001 >nul
cd /d "%~dp0wizardry-cli"
echo === Wizardry Game Test ===
echo.
perl test_game.pl
pause