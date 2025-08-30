# Perl PATH設定ガイド

## 🚨 問題: 'perl' is not recognized

この問題は、WindowsのPATH環境変数にPerlのパスが設定されていないために発生します。

## 🎯 即座に解決する方法

### 方法1: 直接パス指定バッチファイル（推奨・簡単）
```cmd
wizardry_direct.bat    # ゲーム実行
test_direct.bat        # テスト実行
```

これらのファイルはPerlの完全パスを直接指定するため、PATH設定不要で動作します。

### 方法2: PATH環境変数を設定

#### A. PowerShellスクリプトで自動設定（推奨）
```powershell
# 管理者としてPowerShellを実行し、以下を実行
.\fix_perl_path.ps1
```

#### B. 手動でPATH設定
1. **Windows設定を開く**
   - `Win + R` → `sysdm.cpl` → Enter
   - 「詳細設定」タブ → 「環境変数」ボタン

2. **システム環境変数を編集**
   - 「システム環境変数」の「Path」を選択 → 「編集」
   - 「新規」をクリック
   - `C:\Program Files\Git\usr\bin` を追加
   - 「OK」で保存

3. **PowerShellを再起動**

## 🍓 Strawberry Perlインストール（完全解決）

### 自動インストール
```powershell
# 管理者権限でPowerShell実行
Set-ExecutionPolicy Bypass -Scope Process -Force
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
choco install strawberryperl -y
```

### 手動インストール
1. https://strawberryperl.com/ にアクセス
2. 「Download Strawberry Perl」をクリック
3. 64-bit版をダウンロード（約100MB）
4. インストーラーを実行（管理者権限推奨）
5. PowerShellを再起動

## 🔧 現在の状況確認

### Perlが使用可能かチェック
```cmd
perl --version
```

### 使用可能なPerl環境をチェック
```cmd
where perl
```

### ゲームに必要なモジュールチェック
```cmd
perl -e "use JSON; use Term::ANSIColor; use Encode; print 'All modules OK'"
```

## 🎮 ゲーム実行方法（状況別）

### Git付属Perlを使用（現在の状況）
```cmd
wizardry_direct.bat    # 直接パス指定で実行
```

### PATH設定済みの場合
```cmd
wizardry.bat           # 通常のバッチファイル
```

### PowerShell環境
```powershell
.\run_game.ps1         # PowerShellスクリプト
```

### 直接実行
```cmd
cd wizardry-cli
"C:\Program Files\Git\usr\bin\perl.exe" wizardry.pl
```

## 🐛 トラブルシューティング

### エラー: "アクセスが拒否されました"
- 管理者権限でPowerShellを実行してください

### エラー: "実行ポリシーで禁止されています"
```powershell
Set-ExecutionPolicy Bypass -Scope Process
```

### エラー: "パスが見つかりません"
- Gitがインストールされているか確認
- パスが正確か確認: `C:\Program Files\Git\usr\bin`

### 文字化けが発生
- コマンドプロンプトで `chcp 65001` を実行
- フォントを「MS Gothic」に変更

## ✅ 推奨手順

1. **すぐにゲームを試したい場合**:
   ```cmd
   wizardry_direct.bat
   ```

2. **環境を整えたい場合**:
   ```powershell
   # 管理者権限でPowerShell実行
   .\fix_perl_path.ps1
   # PowerShell再起動後
   perl --version
   wizardry.bat
   ```

3. **完全な環境が欲しい場合**:
   - Strawberry Perlをインストール
   - PATH自動設定
   - 豊富なモジュールライブラリ利用可能

## 📂 作成されたファイル

- `wizardry_direct.bat` - 直接パス指定版（推奨）
- `test_direct.bat` - テスト実行版
- `fix_perl_path.ps1` - PATH自動設定
- `install_strawberry_simple.ps1` - Strawberry Perl案内

**今すぐゲームを楽しみたい場合は `wizardry_direct.bat` をダブルクリック！**