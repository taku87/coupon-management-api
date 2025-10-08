# クーポン管理API

店舗向けクーポン管理システムのREST API

## 技術スタック

- **Ruby**: 3.3.5
- **Rails**: 8.0.3 (API mode)
- **Database**: PostgreSQL 16
- **認証**: JWT (RS256)
- **認可**: Pundit
- **テスト**: RSpec, FactoryBot

## 環境構築

### オプション1: Docker環境（推奨）

Docker Composeを使用した環境構築。チーム全体で統一された環境を簡単に構築できます。

#### 必要な環境

- Docker Desktop
- Docker Compose

#### セットアップ手順

```bash
# 1. リポジトリクローン
git clone <repository-url>
cd coupon-management-api

# 2. 環境変数ファイル作成
cp .env.sample .env
# Docker環境の場合、.envはデフォルト設定のままでOK

# 3. Dockerコンテナ起動
docker compose up -d

# 4. データベース作成
docker compose exec app rails db:create

# 5. スキーマ適用
docker compose exec app bundle exec ridgepole -c config/database.yml -E development -f db/Schemafile --apply

# 6. サンプルデータ投入
docker compose exec app bundle exec rails db:seed

# 7. 動作確認
# ブラウザで http://localhost:3000/up にアクセス
# "ok"が表示されれば成功

# 8. コンテナ停止
docker compose down
```

#### Dockerコンテナの管理

```bash
# コンテナ起動
docker compose up -d

# コンテナ状態確認
docker compose ps

# アプリケーションログ確認
docker compose logs app

# コンテナに入る
docker compose exec app bash

# コンテナ停止
docker compose down
```

### オプション2: ローカル環境

ローカルにRubyとPostgreSQLをインストールする場合。

#### 必要な環境

- Ruby 3.3.5
- PostgreSQL 16
- Bundler

#### PostgreSQLのインストール（macOS）

```bash
# Homebrewでインストール
brew install postgresql@16

# PostgreSQL起動
brew services start postgresql@16

# 起動確認
psql --version
```

#### セットアップ手順

```bash
# 1. リポジトリクローン
git clone <repository-url>
cd coupon-management-api

# 2. 環境変数ファイル作成・編集
cp .env.sample .env

# .envを以下のように編集（ローカル環境用）
# DATABASE_HOST=localhost
# DATABASE_PORT=5432
# DATABASE_USERNAME=postgres
# DATABASE_PASSWORD=（ローカルPostgreSQLのパスワード、未設定なら空）

# 3. 依存関係インストール
bundle install

# 4. データベース作成
rails db:create

# 5. スキーマ適用
bundle exec ridgepole -c config/database.yml -E development -f db/Schemafile --apply

# 6. サンプルデータ投入
bundle exec rails db:seed

# 7. サーバー起動
rails server

# 8. 動作確認
# ブラウザで http://localhost:3000/up にアクセス
# "ok"が表示されれば成功
```

## テスト実行

### Docker環境

```bash
# 全テスト実行
docker compose exec app bundle exec rspec

# 特定のテストのみ実行
docker compose exec app bundle exec rspec spec/models/
docker compose exec app bundle exec rspec spec/requests/
```

### ローカル環境

```bash
# 全テスト実行
bundle exec rspec

# 特定のテストのみ実行
bundle exec rspec spec/models/
bundle exec rspec spec/requests/
```

## API仕様

### エンドポイント一覧

| メソッド | パス | 概要 | 認証 |
|---------|------|------|------|
| POST | `/api/v1/auth/login` | JWT発行（ログイン） | 不要 |
| GET | `/api/v1/stores/:store_id/coupons` | クーポン一覧取得 | 必須 |
| POST | `/api/v1/stores/:store_id/coupons` | クーポン作成 | 必須 |

詳細は [docs/04_api.md](./docs/04_api.md) を参照してください。

### ローカル動作確認（curl例）

#### 1. JWTトークン取得（ログイン）

```bash
# サンプルストア1でログイン（db/seeds.rbで作成されたストアを使用）
# store_uidはrails consoleで Store.first.id を実行して確認してください
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "auth": {
      "store_uid": 1,
      "scope": "coupon:read coupon:write"
    }
  }'

# レスポンス例:
# {
#   "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImRlZmF1bHQta2V5LWlkIn0...",
#   "token_type": "Bearer",
#   "expires_in": 900,
#   "scope": "coupon:read coupon:write"
# }
```

#### 2. クーポン一覧取得

```bash
# 上記で取得したaccess_tokenを使用
export TOKEN="取得したaccess_token"
# store_idは1を使用（seeds.rbで作成されたストア）

curl http://localhost:3000/api/v1/stores/1/coupons \
  -H "Authorization: Bearer $TOKEN"

# レスポンス例:
# {
#   "data": [
#     {
#       "id": "1",
#       "type": "coupon",
#       "attributes": {
#         "title": "10% OFFクーポン",
#         "discount_percentage": 10,
#         "valid_until": "2025-10-31",
#         "created_at": "2025-10-08T12:00:00.000Z",
#         "updated_at": "2025-10-08T12:00:00.000Z"
#       },
#       "relationships": {
#         "store": {
#           "data": { "id": "1", "type": "store" }
#         }
#       }
#     }
#   ],
#   "meta": {
#     "current_page": 1,
#     "total_pages": 1,
#     "total_count": 5,
#     "per_page": 20
#   }
# }
```

#### 3. クーポン作成

```bash
curl -X POST http://localhost:3000/api/v1/stores/1/coupons \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "type": "coupon",
      "attributes": {
        "title": "新春セール",
        "discount_percentage": 30,
        "valid_until": "2026-01-31"
      }
    }
  }'

# レスポンス例（201 Created）:
# {
#   "data": {
#     "id": "12",
#     "type": "coupon",
#     "attributes": {
#       "title": "新春セール",
#       "discount_percentage": 30,
#       "valid_until": "2026-01-31",
#       "created_at": "2025-10-08T12:30:00.000Z",
#       "updated_at": "2025-10-08T12:30:00.000Z"
#     },
#     "relationships": {
#       "store": {
#         "data": { "id": "1", "type": "store" }
#       }
#     }
#   }
# }
```

## スキーマ管理（Ridgepole）

このプロジェクトではRidgepoleを使用してデータベーススキーマを管理します。

### Docker環境

```bash
# スキーマ適用
docker compose exec app bundle exec ridgepole -c config/database.yml -E development -f db/Schemafile --apply

# 差分確認（dry-run）
docker compose exec app bundle exec ridgepole -c config/database.yml -E development -f db/Schemafile --dry-run
```

### ローカル環境

```bash
# スキーマ適用
bundle exec ridgepole -c config/database.yml -E development -f db/Schemafile --apply

# 差分確認（dry-run）
bundle exec ridgepole -c config/database.yml -E development -f db/Schemafile --dry-run
```

## トラブルシューティング

### データベース接続エラー

**エラー**: `could not translate host name "db" to address`

**原因**: ローカル環境で`.env`のDATABASE_HOSTが`db`（Docker用）になっている

**解決策**: `.env`を編集して`DATABASE_HOST=localhost`に変更

### ポート競合エラー

**エラー**: `Bind for 0.0.0.0:3000 failed: port is already allocated`

**原因**: 既にポート3000が使用されている

**解決策**:
```bash
# 使用中のプロセスを確認
lsof -i :3000

# 既存のRailsサーバーを停止してから再起動
```

## ドキュメント

- [要件定義](docs/01_requirements.md)
- [アーキテクチャ設計](docs/02_architecture.md)
- [データベース設計](docs/03_database.md)
- [API仕様](docs/04_api.md)
- [セキュリティ設計](docs/05_security.md)
- [テスト方針](docs/06_testing.md)
- [実装計画](docs/implementation_plan.md)

## ライセンス

(ライセンス情報をここに記載)
