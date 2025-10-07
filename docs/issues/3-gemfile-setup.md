# Issue #3: Gemfile整備・基本Gem導入

## 背景 / 目的
ridgepole（スキーマ管理）、dotenv-rails（環境変数）、RSpec（テスト）など、プロジェクト全体で使用する基本Gemを導入する。
後続のDB構築・認証・テスト実装の前提となる依存関係を整備する。

- **依存**: #2
- **ラベル**: `backend`, `setup`

---

## スコープ / 作業項目

1. Gemfile にプロダクション用Gem追加
2. Gemfile に開発・テスト用Gem追加
3. `bundle install` 実行
4. RSpec初期化
5. `.rspec` 設定

---

## ゴール / 完了条件（Acceptance Criteria）

- [ ] Gemfile に以下を追加: ridgepole, dotenv-rails, pundit, pagy, jsonapi-serializer, jwt
- [ ] group :development, :test に rspec-rails, factory_bot_rails, faker 追加
- [ ] `bundle install` 成功
- [ ] `rails g rspec:install` 実行完了
- [ ] `.rspec` に `--format documentation` 追加

---

## テスト観点

- **Gem確認**:
  - `bundle list` で全Gem表示
  - `bundle exec rspec --version` で RSpec バージョン確認
- **RSpec初期化確認**:
  - `spec/spec_helper.rb` 存在確認
  - `spec/rails_helper.rb` 存在確認

---

## 参照ドキュメント

- [02_architecture.md](../02_architecture.md) - 技術構成（セクション1）
- [06_testing.md](../06_testing.md) - テスト全体方針

---

## 実装例

```ruby
# Gemfile
gem 'ridgepole'
gem 'dotenv-rails'
gem 'pundit'
gem 'pagy'
gem 'jsonapi-serializer'
gem 'jwt'

group :development, :test do
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'faker'
end
```
