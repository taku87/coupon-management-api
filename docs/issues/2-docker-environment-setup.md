# Issue #2: Docker環境構築（Rails + PostgreSQL）

## 背景 / 目的
RailsアプリケーションとPostgreSQLをコンテナ化し、チーム全体で統一された開発環境を構築する。
ローカル環境の差異を排除し、再現性のある開発基盤を整備する。

- **依存**: #1
- **ラベル**: `infra`, `setup`

---

## スコープ / 作業項目

1. `docker-compose.yml` 作成（app・db定義）
2. `Dockerfile` 作成（Ruby 3.x + bundler構成）
3. コンテナ起動確認
4. `.env.sample` 作成（環境変数テンプレート）

---

## ゴール / 完了条件（Acceptance Criteria）

- [ ] `docker-compose.yml` にapp・db定義を追加
- [ ] `Dockerfile` にRuby 3.x + bundler構成を記述
- [ ] `docker compose up -d` で両コンテナ起動成功
- [ ] `docker compose exec app rails -v` でバージョン確認
- [ ] `.env.sample` を作成し、DATABASE_URL等の例を記載

---

## テスト観点

- **コンテナ確認**:
  - `docker compose ps` で app・db が Up 状態
  - `docker compose logs app` でエラーがない
- **Rails接続確認**:
  - `docker compose exec app rails -v` が正常応答
  - `docker compose exec app bundle -v` が正常応答

---

## 参照ドキュメント

- [02_architecture.md](../02_architecture.md) - 環境構築方針（セクション5）
- [05_security.md](../05_security.md) - 環境変数管理

---

## 実装例

```yaml
# docker-compose.yml
services:
  db:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data

  app:
    build: .
    command: bundle exec rails s -b 0.0.0.0
    volumes:
      - .:/app
    ports:
      - "3000:3000"
    depends_on:
      - db
    env_file: .env

volumes:
  postgres_data:
```
