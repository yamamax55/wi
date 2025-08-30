@echo off
echo === Wizardry CLI Game Startup ===

cd /d "%~dp0"

if not exist "wizardry-cli" (
    echo Error: wizardry-cli directory not found
    pause
    exit /b 1
)

cd wizardry-cli

perl --version >nul 2>&1
if errorlevel 1 (
    echo Error: Perl not found
    echo Please install Strawberry Perl: https://strawberryperl.com/
    pause
    exit /b 1
)

echo Checking Perl modules...
perl -e "use JSON; use Term::ANSIColor; use Encode; print 'All modules OK\n';" 2>nul
if errorlevel 1 (
    echo Error: Required Perl modules not found
    echo Please run setup_perl.ps1 first
    pause
    exit /b 1
)

if not exist "wizardry.pl" (
    echo Error: wizardry.pl not found
    pause
    exit /b 1
)

echo Starting Wizardry CLI Game...
echo Press Ctrl+C to exit
echo.

perl wizardry.pl

echo.
echo Game ended.
pause