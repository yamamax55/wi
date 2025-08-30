# PowerShell script to setup Perl for Wizardry game
# Run as Administrator if needed

Write-Host "=== Perl環境セットアップ ===" -ForegroundColor Cyan

# Check if we're running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "注意: 管理者権限で実行することを推奨します" -ForegroundColor Yellow
}

# Check if Strawberry Perl is already installed
$strawberryPath = "C:\strawberry\perl\bin\perl.exe"
if (Test-Path $strawberryPath) {
    Write-Host "Strawberry Perlが見つかりました: $strawberryPath" -ForegroundColor Green
    $perlPath = $strawberryPath
} else {
    # Check current Perl
    $currentPerl = Get-Command perl -ErrorAction SilentlyContinue
    if ($currentPerl) {
        Write-Host "現在のPerl: $($currentPerl.Source)" -ForegroundColor Yellow
        $perlPath = $currentPerl.Source
    } else {
        Write-Host "Perlが見つかりません。" -ForegroundColor Red
        Write-Host "Strawberry Perlをダウンロードしてインストールしてください:" -ForegroundColor Yellow
        Write-Host "https://strawberryperl.com/" -ForegroundColor Blue
        exit 1
    }
}

# Test Perl version
Write-Host "`n--- Perl バージョン確認 ---" -ForegroundColor Cyan
& $perlPath --version

# Check and install required modules
Write-Host "`n--- 必要なモジュールをチェック ---" -ForegroundColor Cyan

$requiredModules = @("JSON", "Term::ANSIColor", "Encode")
$missingModules = @()

foreach ($module in $requiredModules) {
    Write-Host "チェック中: $module" -NoNewline
    $result = & $perlPath -e "use $module; print 'OK'" 2>$null
    if ($result -eq "OK") {
        Write-Host " ✓" -ForegroundColor Green
    } else {
        Write-Host " ✗" -ForegroundColor Red
        $missingModules += $module
    }
}

# Install missing modules if any
if ($missingModules.Count -gt 0) {
    Write-Host "`n--- 不足モジュールをインストール ---" -ForegroundColor Yellow
    
    foreach ($module in $missingModules) {
        Write-Host "インストール中: $module"
        
        if (Test-Path "C:\strawberry\perl\bin\cpan.bat") {
            # Use Strawberry Perl's cpan
            & "C:\strawberry\perl\bin\cpan.bat" install $module
        } else {
            # Try alternative installation methods
            Write-Host "CPANが利用できません。手動インストールが必要です。" -ForegroundColor Red
            Write-Host "Strawberry Perlのインストールを推奨します。" -ForegroundColor Yellow
        }
    }
}

# Test the game
Write-Host "`n--- ゲームテスト ---" -ForegroundColor Cyan
$gameDir = Join-Path $PSScriptRoot "wizardry-cli"

if (Test-Path $gameDir) {
    Set-Location $gameDir
    Write-Host "ゲームディレクトリ: $gameDir"
    
    # Syntax check
    Write-Host "構文チェック実行中..."
    $syntaxCheck = & $perlPath -c "wizardry.pl" 2>&1
    Write-Host $syntaxCheck
    
    if ($syntaxCheck -like "*syntax OK*") {
        Write-Host "✓ 構文チェック成功" -ForegroundColor Green
        
        # Run test
        Write-Host "`nテスト実行中..."
        & $perlPath "test_game.pl"
        
        Write-Host "`n=== セットアップ完了 ===" -ForegroundColor Green
        Write-Host "ゲームを開始するには:" -ForegroundColor Cyan
        Write-Host "cd $gameDir" -ForegroundColor White
        Write-Host "perl wizardry.pl" -ForegroundColor White
    } else {
        Write-Host "✗ 構文エラーがあります" -ForegroundColor Red
    }
} else {
    Write-Host "ゲームディレクトリが見つかりません: $gameDir" -ForegroundColor Red
}

Write-Host "`nPowerShellでPerlを使うためのエイリアス設定:" -ForegroundColor Cyan
Write-Host "Set-Alias -Name perl -Value '$perlPath'" -ForegroundColor White