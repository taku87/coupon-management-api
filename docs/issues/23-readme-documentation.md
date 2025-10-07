# Issue #23: README.md・環境構築手順整備

## 背景 / 目的
環境構築・起動・テスト実行手順を最終化し、新規開発者のオンボーディングを円滑化する。
API仕様と動作確認手順を明記し、プロジェクトの理解を促進する。

- **依存**: #22
- **ラベル**: `docs`

---

## スコープ / 作業項目

1. README.md にDocker構築手順追加
2. ridgepole適用手順追加
3. API仕様（エンドポイント一覧）追加
4. ローカル動作確認手順（curl例）追加
5. 新規開発者による環境構築検証

---

## ゴール / 完了条件（Acceptance Criteria）

- [ ] README.md にDocker構築手順・ridgepole適用手順を記載
- [ ] `.env.sample` に必要な環境変数（JWT_PRIVATE_KEY等）を例示
- [ ] API仕様（エンドポイント一覧）を簡潔に記載
- [ ] ローカル動作確認手順（curl例）を追加
- [ ] 新規開発者がREADME通りに環境構築できることを確認

---

## テスト観点

- **ドキュメント確認**:
  - 手順通りに環境構築できる
  - API仕様が明確
  - curl例で動作確認できる

---

## 参照ドキュメント

- [02_architecture.md](../02_architecture.md) - 環境構築方針
- [04_api.md](../04_api.md) - API仕様

---

## 実装例

```markdown
# Coupon Management API

Ruby on Railsを用いたクーポン管理REST APIです。

## 環境構築

### 必要なツール

- Docker Desktop
- Git

### セットアップ手順

1. リポジトリをクローン
\`\`\`bash
git clone <repository-url>
cd coupon-management-api
\`\`\`

2. 環境変数設定
\`\`\`bash
cp .env.sample .env
# .env を編集し、JWT_PRIVATE_KEY等を設定
\`\`\`

3. Dockerコンテナ起動
\`\`\`bash
docker compose build
docker compose up -d
\`\`\`

4. データベース作成・スキーマ適用
\`\`\`bash
docker compose exec app rails db:create
docker compose exec app bundle exec ridgepole -c config/database.yml -E development -f db/Schemafile --apply
\`\`\`

5. サンプルデータ投入
\`\`\`bash
docker compose exec app rails db:seed
\`\`\`

6. 動作確認
\`\`\`bash
# ログイン（JWTトークン取得）
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"store_id": 1}'

# クーポン一覧取得
curl http://localhost:3000/api/v1/stores/1/coupons \
  -H "Authorization: Bearer <token>"
\`\`\`

## API仕様

| メソッド | パス | 概要 |
|---------|------|------|
| POST | `/api/v1/auth/login` | JWT発行 |
| GET | `/api/v1/stores/:store_id/coupons` | クーポン一覧取得 |
| POST | `/api/v1/stores/:store_id/coupons` | クーポン作成 |

詳細は [docs/04_api.md](./docs/04_api.md) を参照。

## テスト実行

\`\`\`bash
docker compose exec app bundle exec rspec
\`\`\`

## ドキュメント

- [要件定義](./docs/01_requirements.md)
- [アーキテクチャ](./docs/02_architecture.md)
- [データベース設計](./docs/03_database.md)
- [API仕様](./docs/04_api.md)
- [セキュリティ](./docs/05_security.md)
- [テスト方針](./docs/06_testing.md)
```
