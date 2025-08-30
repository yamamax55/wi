# Strawberry Perl自動インストールスクリプト
# 管理者権限で実行してください

Write-Host "=== Strawberry Perl 自動インストール ===" -ForegroundColor Cyan

# 管理者権限チェック
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "このスクリプトは管理者権限で実行する必要があります。" -ForegroundColor Red
    Write-Host "PowerShellを管理者として再起動して、再実行してください。" -ForegroundColor Yellow
    pause
    exit 1
}

# Strawberry Perlがすでにインストールされているかチェック
if (Test-Path "C:\strawberry\perl\bin\perl.exe") {
    Write-Host "Strawberry Perlは既にインストールされています。" -ForegroundColor Green
    exit 0
}

# Chocolateyがインストールされているかチェック
$chocoPath = Get-Command choco -ErrorAction SilentlyContinue

if ($chocoPath) {
    Write-Host "Chocolateyを使用してStrawberry Perlをインストールします..." -ForegroundColor Yellow
    choco install strawberryperl -y
} else {
    Write-Host "Chocolateyが見つかりません。直接ダウンロードします..." -ForegroundColor Yellow
    
    # Strawberry Perlの最新版URLを取得（簡略化）
    $downloadUrl = "https://strawberryperl.com/download/5.38.2.2/strawberry-perl-5.38.2.2-64bit.msi"
    $installerPath = "$env:TEMP\strawberry-perl-installer.msi"
    
    try {
        Write-Host "ダウンロード中: $downloadUrl"
        Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath -UseBasicParsing
        
        Write-Host "インストール中..."
        Start-Process msiexec.exe -ArgumentList "/i `"$installerPath`" /quiet /norestart" -Wait
        
        # インストーラーファイルを削除
        Remove-Item $installerPath -ErrorAction SilentlyContinue
        
        Write-Host "Strawberry Perlのインストールが完了しました！" -ForegroundColor Green
        
    } catch {
        Write-Host "自動ダウンロードに失敗しました。" -ForegroundColor Red
        Write-Host "手動でダウンロードしてください: https://strawberryperl.com/" -ForegroundColor Yellow
        Start-Process "https://strawberryperl.com/"
        exit 1
    }
}

# 環境変数の更新
Write-Host "環境変数を更新中..." -ForegroundColor Yellow
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# インストール確認
if (Test-Path "C:\strawberry\perl\bin\perl.exe") {
    Write-Host "✓ インストール成功！" -ForegroundColor Green
    & "C:\strawberry\perl\bin\perl.exe" --version
} else {
    Write-Host "✗ インストールに失敗しました。" -ForegroundColor Red
    Write-Host "手動インストールが必要です: https://strawberryperl.com/" -ForegroundColor Yellow
}

Write-Host "`n次のステップ:" -ForegroundColor Cyan
Write-Host "1. PowerShellを再起動してください" -ForegroundColor White
Write-Host "2. setup_perl.ps1 を実行してください" -ForegroundColor White

pause