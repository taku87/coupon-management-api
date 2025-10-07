# Issue #1: Rails APIプロジェクト初期化

## 背景 / 目的
クーポン管理APIの基盤となるRails 8.0 API modeプロジェクトを作成し、バージョン管理を開始する。
後続のDocker環境構築・Gem導入の前提となる初期セットアップを完了させる。

- **依存**: -
- **ラベル**: `backend`, `setup`

---

## スコープ / 作業項目

1. Rails 8.0 API modeプロジェクト新規作成
2. `.gitignore` 整備（機密情報・一時ファイル除外）
3. README.md 雛形作成
4. Git初期化・初回コミット

---

## ゴール / 完了条件（Acceptance Criteria）

- [ ] `rails new coupon-management-api --api --database=postgresql` 実行完了
- [ ] `.gitignore` に `.env`, `log/`, `tmp/` を追加
- [ ] README.md に環境構築手順の雛形を記載
- [ ] `git init` & 初回コミット完了

---

## テスト観点

- **環境確認**:
  - `rails -v` でRails 8.0が表示される
  - `config/database.yml` にPostgreSQL設定が存在
- **Git確認**:
  - `.git/` ディレクトリ存在確認
  - `git log` で初回コミット確認

---

## 参照ドキュメント

- [02_architecture.md](../02_architecture.md) - システム構成概要
- [01_requirements.md](../01_requirements.md) - 完了条件（Definition of Done）

---

## 要確認事項

- Ruby バージョン（推奨: 3.2以上）の確認
