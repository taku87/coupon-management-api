# クーポン管理API

店舗向けクーポン管理システムのREST API

## 技術スタック

- **Ruby**: 3.3.5
- **Rails**: 8.0.3 (API mode)
- **Database**: PostgreSQL
- **認証**: JWT (RS256)
- **認可**: Pundit
- **テスト**: RSpec, FactoryBot

## 環境構築

### 必要な環境

- Ruby 3.2以上
- PostgreSQL
- Docker & Docker Compose（推奨）

### セットアップ手順

```bash
# リポジトリクローン
git clone <repository-url>
cd coupon-management-api

# 環境変数設定
cp .env.sample .env
# .env を編集して必要な環境変数を設定

# 依存関係インストール
bundle install

# データベース作成・マイグレーション
rails db:create
bundle exec ridgepole -c config/database.yml -E development -f db/Schemafile --apply

# サーバー起動
rails server
```

### Docker環境でのセットアップ

```bash
# コンテナ起動
docker compose up -d

# データベース作成・マイグレーション
docker compose exec app rails db:create
docker compose exec app bundle exec ridgepole -c config/database.yml -E development -f db/Schemafile --apply
```

## テスト実行

```bash
# 全テスト実行
bundle exec rspec

# 特定のテストのみ実行
bundle exec rspec spec/models/
bundle exec rspec spec/requests/
```

## ドキュメント

- [要件定義](docs/01_requirements.md)
- [アーキテクチャ設計](docs/02_architecture.md)
- [データベース設計](docs/03_database.md)
- [API仕様](docs/04_api.md)
- [セキュリティ設計](docs/05_security.md)
- [テスト方針](docs/06_testing.md)

## ライセンス

(ライセンス情報をここに記載)
