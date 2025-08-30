# Wizardry Game Launcher for PowerShell
# UTF-8 BOM encoding

param(
    [switch]$Test
)

# Set console encoding
$OutputEncoding = [console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding

Write-Host "=== Wizardry CLI Game Launcher ===" -ForegroundColor Cyan

# Get script directory and game directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$gameDir = Join-Path $scriptDir "wizardry-cli"

Write-Host "Script Directory: $scriptDir"
Write-Host "Game Directory: $gameDir"

if (-not (Test-Path $gameDir)) {
    Write-Host "ERROR: Game directory not found: $gameDir" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Change to game directory
Set-Location $gameDir

# Check for Perl
$perlCmd = Get-Command perl -ErrorAction SilentlyContinue
if (-not $perlCmd) {
    Write-Host "ERROR: Perl not found in PATH" -ForegroundColor Red
    Write-Host "Please install Strawberry Perl: https://strawberryperl.com/" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Perl found: $($perlCmd.Source)" -ForegroundColor Green

# Test required modules
Write-Host "Checking required modules..." -ForegroundColor Yellow
$modules = @("JSON", "Term::ANSIColor", "Encode")
$moduleOK = $true

foreach ($module in $modules) {
    try {
        $result = & perl -e "use $module; print 'OK'" 2>&1
        if ($result -eq "OK") {
            Write-Host "  OK: $module" -ForegroundColor Green
        } else {
            Write-Host "  FAIL: $module" -ForegroundColor Red
            $moduleOK = $false
        }
    } catch {
        Write-Host "  ERROR: $module - $($_.Exception.Message)" -ForegroundColor Red
        $moduleOK = $false
    }
}

if (-not $moduleOK) {
    Write-Host "Some modules are missing. Game may not work properly." -ForegroundColor Yellow
}

# Check game files
if (-not (Test-Path "wizardry.pl")) {
    Write-Host "ERROR: wizardry.pl not found" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Syntax check
Write-Host "Checking syntax..." -ForegroundColor Yellow
try {
    $syntaxResult = & perl -c "wizardry.pl" 2>&1
    if ($syntaxResult -match "syntax OK") {
        Write-Host "Syntax check: OK" -ForegroundColor Green
    } else {
        Write-Host "Syntax check failed:" -ForegroundColor Red
        Write-Host $syntaxResult -ForegroundColor Red
        Read-Host "Press Enter to continue anyway"
    }
} catch {
    Write-Host "Syntax check error: $($_.Exception.Message)" -ForegroundColor Red
}

# Run game or test
Write-Host ""
Write-Host "=" * 50 -ForegroundColor Yellow

if ($Test) {
    Write-Host "Running test..." -ForegroundColor Cyan
    & perl test_game.pl
} else {
    Write-Host "Starting Wizardry CLI Game!" -ForegroundColor Cyan
    Write-Host "Press Ctrl+C to exit" -ForegroundColor Yellow
    Write-Host "=" * 50 -ForegroundColor Yellow
    Write-Host ""
    
    try {
        & perl wizardry.pl
    } catch {
        Write-Host "Game execution error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Game session ended." -ForegroundColor Green