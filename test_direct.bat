@echo off
chcp 65001 >nul
echo === Wizardry Game Test ===
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

REM テスト実行
"%PERL_PATH%" test_game.pl

echo.
echo Test completed.
pause