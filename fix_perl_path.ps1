# PowerShellでPerlを使えるようにするスクリプト
# 管理者権限で実行することを推奨

Write-Host "=== Perl PATH修正スクリプト ===" -ForegroundColor Cyan

# 管理者権限チェック
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "注意: 管理者権限で実行することを推奨します" -ForegroundColor Yellow
    Write-Host "一時的な修正のみ行います" -ForegroundColor Yellow
}

# Git付属Perlのパスを確認
$gitPerlPath = "C:\Program Files\Git\usr\bin"
$gitPerlExe = Join-Path $gitPerlPath "perl.exe"

if (Test-Path $gitPerlExe) {
    Write-Host "Git付属Perlを発見: $gitPerlExe" -ForegroundColor Green
    
    # 現在のセッションでPATHに追加
    $currentPath = $env:PATH
    if ($currentPath -notlike "*$gitPerlPath*") {
        $env:PATH = $gitPerlPath + ";" + $currentPath
        Write-Host "現在のセッションでPATHに追加しました" -ForegroundColor Yellow
    }
    
    # システム環境変数に永続的に追加（管理者権限が必要）
    if ($isAdmin) {
        try {
            $systemPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
            if ($systemPath -notlike "*$gitPerlPath*") {
                $newSystemPath = $systemPath + ";" + $gitPerlPath
                [Environment]::SetEnvironmentVariable("Path", $newSystemPath, [EnvironmentVariableTarget]::Machine)
                Write-Host "システム環境変数PATHに永続的に追加しました" -ForegroundColor Green
                Write-Host "新しいPowerShellセッションでPerlが使用可能になります" -ForegroundColor Cyan
            } else {
                Write-Host "既にシステムPATHに含まれています" -ForegroundColor Green
            }
        } catch {
            Write-Host "システム環境変数の変更に失敗: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "永続的な変更には管理者権限が必要です" -ForegroundColor Yellow
        Write-Host "管理者として再実行するか、現在のセッションでのみ使用してください" -ForegroundColor Yellow
    }
    
} else {
    Write-Host "Git付属Perlが見つかりません" -ForegroundColor Red
    Write-Host "Strawberry Perlのインストールを推奨します" -ForegroundColor Yellow
}

# Perlの動作確認
Write-Host "`n--- Perl動作確認 ---" -ForegroundColor Cyan
try {
    $perlVersion = & perl --version 2>&1
    if ($perlVersion -match "This is perl") {
        Write-Host "✓ Perlが正常に動作しています" -ForegroundColor Green
        Write-Host ($perlVersion -split "`n")[0] -ForegroundColor Green
        
        # 必要なモジュール確認
        Write-Host "`n--- 必要モジュール確認 ---" -ForegroundColor Cyan
        $modules = @("JSON", "Term::ANSIColor", "Encode")
        foreach ($module in $modules) {
            try {
                $result = & perl -e "use $module; print 'OK'" 2>&1
                if ($result -eq "OK") {
                    Write-Host "✓ $module" -ForegroundColor Green
                } else {
                    Write-Host "✗ $module - $result" -ForegroundColor Red
                }
            } catch {
                Write-Host "✗ $module - エラー" -ForegroundColor Red
            }
        }
        
    } else {
        Write-Host "✗ Perlの実行に問題があります" -ForegroundColor Red
        Write-Host $perlVersion -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Perlコマンドが見つかりません" -ForegroundColor Red
    Write-Host "PowerShellを再起動してください" -ForegroundColor Yellow
}

Write-Host "`n--- 次のステップ ---" -ForegroundColor Cyan
Write-Host "1. PowerShellを再起動する（推奨）"
Write-Host "2. または新しいPowerShellウィンドウを開く"
Write-Host "3. perl --version で確認"
Write-Host "4. wizardry.bat でゲーム実行"