# Wizardry風CLIゲーム起動スクリプト

Write-Host "=== Wizardry風CLIゲーム起動 ===" -ForegroundColor Cyan

# ゲームディレクトリに移動
$currentDir = Get-Location
$gameDir = Join-Path $currentDir "wizardry-cli"

if (-not (Test-Path $gameDir)) {
    Write-Host "エラー: ゲームディレクトリが見つかりません: $gameDir" -ForegroundColor Red
    pause
    exit 1
}

Set-Location $gameDir

# Perlの確認
$perl = Get-Command perl -ErrorAction SilentlyContinue
if (-not $perl) {
    Write-Host "エラー: Perlが見つかりません。" -ForegroundColor Red
    Write-Host "Strawberry Perlをインストールしてください: https://strawberryperl.com/" -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "Perl: $($perl.Source)" -ForegroundColor Green

# 必要なモジュールをチェック
Write-Host "必要なモジュールをチェック中..." -ForegroundColor Yellow

$modules = @("JSON", "Term::ANSIColor", "Encode")
$allOK = $true

foreach ($module in $modules) {
    $result = & perl -e "use $module; print 'OK'" 2>$null
    if ($result -eq "OK") {
        Write-Host "✓ $module" -ForegroundColor Green
    } else {
        Write-Host "✗ $module が見つかりません" -ForegroundColor Red
        $allOK = $false
    }
}

if (-not $allOK) {
    Write-Host "`nモジュールが不足しています。setup_perl.ps1を実行してください。" -ForegroundColor Yellow
    pause
    exit 1
}

# ゲーム起動前の最終チェック
Write-Host "`nゲームファイルをチェック中..." -ForegroundColor Yellow
if (-not (Test-Path "wizardry.pl")) {
    Write-Host "エラー: wizardry.pl が見つかりません" -ForegroundColor Red
    pause
    exit 1
}

# 構文チェック
$syntaxCheck = & perl -c "wizardry.pl" 2>&1
if ($syntaxCheck -like "*syntax OK*") {
    Write-Host "✓ 構文チェックOK" -ForegroundColor Green
} else {
    Write-Host "✗ 構文エラー:" -ForegroundColor Red
    Write-Host $syntaxCheck -ForegroundColor Red
    pause
    exit 1
}

# UTF-8対応のためのコンソール設定
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

# ゲーム起動
Write-Host "`n" + "="*50 -ForegroundColor Yellow
Write-Host "Wizardry風CLIゲームを起動します！" -ForegroundColor Cyan
Write-Host "終了するには Ctrl+C を押してください" -ForegroundColor Yellow
Write-Host "="*50 -ForegroundColor Yellow
Write-Host ""

# ゲーム実行
try {
    & perl wizardry.pl
} catch {
    Write-Host "`nゲーム実行中にエラーが発生しました:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

Write-Host "`nゲームを終了しました。" -ForegroundColor Green
pause