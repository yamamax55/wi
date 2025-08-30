# 簡単なStrawberry Perlインストーラー

Write-Host "=== Strawberry Perl簡単インストール ===" -ForegroundColor Cyan

# 管理者権限チェック
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

Write-Host "管理者権限: $(if($isAdmin){'あり'}else{'なし'})" -ForegroundColor $(if($isAdmin){'Green'}else{'Yellow'})

# Strawberry Perlが既にインストール済みかチェック
if (Test-Path "C:\strawberry\perl\bin\perl.exe") {
    Write-Host "Strawberry Perlは既にインストールされています" -ForegroundColor Green
    & "C:\strawberry\perl\bin\perl.exe" --version
    Write-Host "`nゲームを実行するには wizardry_direct.bat を使用してください" -ForegroundColor Cyan
    pause
    exit 0
}

Write-Host "`n以下の方法でStrawberry Perlをインストールできます:" -ForegroundColor Yellow

Write-Host "`n1. 自動インストール（推奨）:" -ForegroundColor Cyan
Write-Host "   - PowerShellを管理者として実行"
Write-Host "   - fix_perl_path.ps1 を実行"

Write-Host "`n2. 手動インストール:" -ForegroundColor Cyan
Write-Host "   - https://strawberryperl.com/ にアクセス"
Write-Host "   - Strawberry Perl 5.38をダウンロード"
Write-Host "   - インストーラーを実行"

Write-Host "`n3. Chocolateyを使用（管理者権限必要）:" -ForegroundColor Cyan
Write-Host "   choco install strawberryperl"

Write-Host "`n4. 現在のGit付属Perlを使用:" -ForegroundColor Cyan
Write-Host "   wizardry_direct.bat を実行"

Write-Host "`n推奨: 今すぐ wizardry_direct.bat を試してみてください！" -ForegroundColor Green

$choice = Read-Host "`nStrawberry Perlをダウンロードページを開きますか？ (y/n)"
if ($choice -eq 'y' -or $choice -eq 'Y') {
    Start-Process "https://strawberryperl.com/"
}