# PowerShellプロファイルにPerl関連の設定を追加

Write-Host "=== PowerShell プロファイル設定 ===" -ForegroundColor Cyan

# PowerShellプロファイルの場所を確認
$profilePath = $PROFILE.CurrentUserCurrentHost
Write-Host "プロファイル場所: $profilePath"

# プロファイルディレクトリが存在しない場合は作成
$profileDir = Split-Path $profilePath -Parent
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force
    Write-Host "プロファイルディレクトリを作成しました: $profileDir" -ForegroundColor Green
}

# 既存のプロファイルをバックアップ
if (Test-Path $profilePath) {
    $backupPath = "$profilePath.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $profilePath $backupPath
    Write-Host "既存プロファイルをバックアップしました: $backupPath" -ForegroundColor Yellow
}

# Perl設定を追加
$perlConfig = @"

# ===== Perl設定 (Wizardry Game) =====
# UTF-8エンコーディング設定
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

# Perl関連のエイリアス
Set-Alias -Name wizardry -Value "$PSScriptRoot\start_game.ps1"

# Perl環境変数
if (Test-Path "C:\strawberry\perl\bin") {
    `$env:PATH = "C:\strawberry\perl\bin;" + `$env:PATH
}

# ゲーム用関数
function Start-WizardryGame {
    Set-Location "$PSScriptRoot\wizardry-cli"
    perl wizardry.pl
}

function Test-WizardryGame {
    Set-Location "$PSScriptRoot\wizardry-cli"
    perl test_game.pl
}

Write-Host "Wizardry Game環境が読み込まれました" -ForegroundColor Green
Write-Host "利用可能なコマンド:" -ForegroundColor Cyan
Write-Host "  wizardry          - ゲーム起動"
Write-Host "  Start-WizardryGame - ゲーム起動"
Write-Host "  Test-WizardryGame  - テスト実行"

"@

# プロファイルに追加
Add-Content -Path $profilePath -Value $perlConfig -Encoding UTF8

Write-Host "`n設定を追加しました！" -ForegroundColor Green
Write-Host "変更を反映するには次のいずれかを実行してください:" -ForegroundColor Yellow
Write-Host "1. PowerShellを再起動"
Write-Host "2. . `$PROFILE を実行"

Write-Host "`n追加された機能:" -ForegroundColor Cyan
Write-Host "- UTF-8エンコーディング自動設定"
Write-Host "- wizardry コマンドでゲーム起動"
Write-Host "- Start-WizardryGame 関数"
Write-Host "- Test-WizardryGame 関数"

# 即座に設定を適用
Write-Host "`n設定を即座に適用しています..." -ForegroundColor Yellow
. $profilePath

Write-Host "完了！" -ForegroundColor Green