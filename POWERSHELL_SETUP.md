# PowerShellでWizardry風CLIゲームを実行する方法

## 🚀 簡単な実行方法

### 方法1: バッチファイル（推奨）
```cmd
# ゲーム実行
wizardry.bat

# テスト実行
test_wizardry.bat
```

### 方法2: PowerShellスクリプト
```powershell
# ゲーム実行
.\run_game.ps1

# テスト実行
.\run_game.ps1 -Test
```

### 方法3: 直接実行
```powershell
cd wizardry-cli
perl wizardry.pl
```

## 🔧 Perl環境セットアップ

### 現在の状況確認
現在、Git付属のPerlが利用可能で、必要なモジュール（JSON, Term::ANSIColor, Encode）も既にインストールされています。

```powershell
# Perlバージョン確認
perl --version

# 必要モジュール確認
perl -e "use JSON; use Term::ANSIColor; use Encode; print 'All OK'"
```

### より完全なPerl環境が必要な場合

#### Strawberry Perlのインストール（推奨）
1. **自動インストール（管理者権限必要）**:
   ```powershell
   .\install_strawberry_perl.ps1
   ```

2. **手動インストール**:
   - https://strawberryperl.com/ からダウンロード
   - インストーラーを実行

#### Chocolateyを使用（管理者権限必要）
```powershell
# Chocolateyがない場合はインストール
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Strawberry Perlインストール
choco install strawberryperl -y
```

## 🎮 ゲーム実行

### PowerShell環境設定（オプション）
```powershell
# PowerShellプロファイルにゲーム用設定を追加
.\PowerShell_Profile_Setup.ps1

# 設定を即座に反映
. $PROFILE
```

設定後は以下のコマンドが使用可能:
- `wizardry` - ゲーム起動
- `Start-WizardryGame` - ゲーム起動
- `Test-WizardryGame` - テスト実行

### 文字化け対策
PowerShellで文字化けが発生する場合:

```powershell
# UTF-8エンコーディング設定
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

# またはコードページ変更
chcp 65001
```

## 🐛 トラブルシューティング

### エラー: "perl が認識されません"
- Perlがインストールされていません
- 環境変数PATHにPerlのパスが設定されていません

**解決方法**:
1. Strawberry Perlをインストール
2. PowerShellを再起動
3. `perl --version` で確認

### エラー: "モジュールが見つかりません"
**解決方法**:
```cmd
# CPANでモジュールをインストール
cpan install JSON
cpan install Term::ANSIColor
```

### 文字化けが発生する
**解決方法**:
1. PowerShellのフォントを"Consolas"や"MS Gothic"に変更
2. UTF-8エンコーディングを設定
3. バッチファイル（.bat）を使用

### PowerShellの実行ポリシーエラー
```powershell
# 実行ポリシーを変更（管理者権限）
Set-ExecutionPolicy RemoteSigned -Scope LocalMachine

# または現在のセッションのみ
Set-ExecutionPolicy Bypass -Scope Process
```

## 📂 ファイル構成

```
wi/
├── wizardry.bat              # 簡単実行用バッチ
├── test_wizardry.bat         # テスト実行用バッチ
├── run_game.ps1              # PowerShell実行スクリプト
├── setup_perl.ps1            # Perl環境チェック
├── install_strawberry_perl.ps1  # 自動インストール
├── PowerShell_Profile_Setup.ps1 # プロファイル設定
└── wizardry-cli/             # ゲーム本体
    ├── wizardry.pl           # メインゲーム
    ├── test_game.pl          # テストスクリプト
    └── lib/                  # ゲームライブラリ
```

## ✅ 動作確認

全て正常に動作していれば:
1. `test_wizardry.bat` でテスト実行
2. `wizardry.bat` でゲーム開始
3. キャラクター作成から戦闘まで楽しめます！