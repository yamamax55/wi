@echo off
chcp 65001 >nul
echo === Wizardry CLI Game ===
echo.

REM Git付属Perlの直接パスを使用
set PERL_PATH=C:\Program Files\Git\usr\bin\perl.exe

REM Perlの存在確認
if not exist "%PERL_PATH%" (
    echo ERROR: Perl not found at %PERL_PATH%
    echo Please check if Git is installed
    pause
    exit /b 1
)

echo Using Perl: %PERL_PATH%
echo.

REM ゲームディレクトリに移動
cd /d "%~dp0wizardry-cli"

REM ゲーム実行
"%PERL_PATH%" wizardry.pl

echo.
echo Game ended.
pause