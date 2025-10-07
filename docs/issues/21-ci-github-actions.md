# Issue #21: CI構築（GitHub Actions）

## 背景 / 目的
GitHub ActionsでRSpec自動実行環境を構築し、PR時の品質担保を実現する。
テストの自動化により、リグレッション検知と開発速度向上を両立する。

- **依存**: #20
- **ラベル**: `infra`, `ci`

---

## スコープ / 作業項目

1. `.github/workflows/ci.yml` 作成
2. PostgreSQLサービスコンテナ定義
3. ridgepole --apply でテスト用DB構築
4. RSpec実行
5. PR時のCI必須チェック設定

---

## ゴール / 完了条件（Acceptance Criteria）

- [ ] `.github/workflows/ci.yml` 作成
- [ ] PostgreSQLサービスコンテナ定義
- [ ] ridgepole --apply でテスト用DB構築
- [ ] `bundle exec rspec` 実行
- [ ] PRマージ前にCI必須チェック設定
- [ ] CI実行成功（グリーンバッジ）

---

## テスト観点

- **CI確認**:
  - PR作成時にCI自動実行
  - テスト失敗時にPRマージ不可
  - CI成功時にグリーンバッジ表示

---

## 参照ドキュメント

- [06_testing.md](../06_testing.md) - CI/CD連携（セクション10）
- [02_architecture.md](../02_architecture.md) - 環境構築方針

---

## 実装例

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_PASSWORD: password
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

    steps:
      - uses: actions/checkout@v4

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.2
          bundler-cache: true

      - name: Setup Database
        env:
          DATABASE_URL: postgres://postgres:password@localhost:5432/test
        run: |
          bundle exec rails db:create RAILS_ENV=test
          bundle exec ridgepole -c config/database.yml -E test -f db/Schemafile --apply

      - name: Run RSpec
        env:
          DATABASE_URL: postgres://postgres:password@localhost:5432/test
        run: bundle exec rspec --format documentation
```

---

## 要確認事項

- CI環境での環境変数注入方法（GitHub Secrets利用）
- JWT_PRIVATE_KEY などの秘密情報管理
