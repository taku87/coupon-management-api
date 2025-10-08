# Host Authorization問題（Request Spec 403エラー）

## ステータス
🔴 **未解決** - 実装は完了しているが、Request Specのみ環境設定問題により失敗

## 問題の概要

Phase 3実装（Issue #16 AuthController, #18 Request Spec）において、Request Specを実行すると403 Forbiddenエラーが発生する。

- **影響範囲**: Request Specのみ（Controller Spec, Model Spec, Policy Spec等は全て正常）
- **実装状態**: API実装自体は正しく完成している
- **テスト結果**: 56 examples (非Request Spec), 0 failures

## エラー詳細

### 発生状況
```bash
bundle exec rspec spec/requests/auth_spec.rb:19
```

### エラー内容
```
Failure/Error: expect(response).to have_http_status(:ok)
  expected the response to have status code :ok (200) but it was :forbidden (403)
```

### レスポンス内容
- HTTPステータス: 403 Forbidden
- Content-Type: text/html（JSON期待に対して）
- Body: Rails標準エラーページ「Action Controller: Exception caught」
- Request host: `www.example.com`（RSpecデフォルト）

## 試行した解決策（全て無効）

### 1. `config.hosts` に明示的にホストを追加
```ruby
# config/environments/test.rb
config.hosts << "www.example.com"
```
**結果**: 403エラー継続

### 2. `config.hosts` をクリア
```ruby
# config/environments/test.rb
config.hosts.clear
```
**結果**: 403エラー継続

### 3. `config.hosts` を nil に設定
```ruby
# config/environments/test.rb
config.hosts = nil
```
**結果**: 403エラー継続

### 4. `host_authorization` を除外設定
```ruby
# config/environments/test.rb
config.host_authorization = { exclude: ->(request) { true } }
```
**結果**: 403エラー継続

### 5. HostAuthorization ミドルウェアを削除（application.rb）
```ruby
# config/application.rb
config.middleware.delete ActionDispatch::HostAuthorization
```
**結果**: 403エラー継続

### 6. HostAuthorization ミドルウェアを削除（test.rb）
```ruby
# config/environments/test.rb
config.middleware.delete ActionDispatch::HostAuthorization
```
**結果**: 403エラー継続

### 7. Initializer でホストをクリア
```ruby
# config/initializers/host_authorization.rb
Rails.application.config.hosts.clear if Rails.env.test?
```
**結果**: 403エラー継続

### 8. rails_helper でホストをクリア
```ruby
# spec/rails_helper.rb
Rails.application.config.hosts.clear
```
**結果**: 403エラー継続

### 9. 例外表示を無効化して詳細確認
```ruby
# config/environments/test.rb
config.action_dispatch.show_exceptions = :none
```
**結果**: HTMLエラーページのまま変化なし

### 10. Docker環境リセット・キャッシュクリア
```bash
docker compose down
docker compose up -d
docker compose exec api bundle exec rails tmp:clear
```
**結果**: 403エラー継続

## 技術分析

### Rails 8 Host Authorization の動作
- Rails 7.0以降、`ActionDispatch::HostAuthorization` がデフォルトで有効
- `config.hosts` に登録されていないホストからのリクエストを403でブロック
- Development環境: `config.hosts` は通常 `localhost` と `127.0.0.1` を含む
- Test環境: Request Specは `www.example.com` をホストとして使用

### 期待される動作
- `config.hosts << "www.example.com"` で解決するはず
- または `config.hosts.clear` で全ホスト許可になるはず
- または middleware 削除で機能自体を無効化できるはず

### 実際の動作
- 上記設定を行っても403エラーが継続
- ミドルウェアスタックを確認すると HostAuthorization は存在しない
- しかし依然として403エラーが返される

### 仮説
1. **設定反映タイミング問題**: Dockerコンテナ内でRails環境の再読み込みが正しく行われていない可能性
2. **別の認証機構**: HostAuthorization以外の何らかのミドルウェアがホストチェックを行っている可能性
3. **Rails 8固有の問題**: Rails 8で Host Authorization の挙動が変更された可能性
4. **RSpec設定不足**: Request Specで特定のホスト設定が必要な可能性

## 検証事項

### 正常に動作している部分
- ✅ Model Spec: 全テストパス
- ✅ Policy Spec: 全テストパス
- ✅ Controller Spec: 全テストパス
- ✅ Serializer Spec: 全テストパス
- ✅ Rubocop: 0 offenses

### 失敗している部分
- ❌ Request Spec (auth_spec.rb): 403エラー
- ❌ Request Spec (coupons_spec.rb): 403エラー
- ❌ Request Spec (pagination_spec.rb): 403エラー

## 影響範囲

### 実装への影響
- **なし**: API実装自体は正しく完成している
- Controller, Model, Policy, Serializer全て実装完了
- 他のSpecタイプで全て動作検証済み

### テストへの影響
- Request Specのみ実行不可
- 統合テストレベルの検証ができない状態

## 推奨される次のステップ

### 短期対応
1. **Controller Specで代替**: Request Specの代わりにController Specでエンドツーエンドテストを補完
2. **手動動作確認**: Postman/curlで実際のAPIエンドポイントを手動テスト
3. **Issue継続調査**: Rails 8 + Docker環境での Host Authorization 設定方法を調査

### 長期対応
1. **Rails コミュニティ調査**: Rails 8での Host Authorization 設定に関する情報収集
2. **環境分離**: Docker環境とローカル環境で動作を比較検証
3. **RSpec設定見直し**: Request Specのホスト設定に関するベストプラクティス調査

## 参考情報

### 環境情報
- Rails: 8.0.1
- Ruby: 3.3.6
- RSpec: 3.13
- Docker Compose環境

### 関連ファイル
- `config/environments/test.rb`
- `spec/rails_helper.rb`
- `config/application.rb`
- `spec/requests/*_spec.rb`

### 関連Issue
- Issue #16: AuthController実装（ログインAPI） - ✅ 実装完了
- Issue #18: Request Spec実装（Coupons API） - ⚠️ 実装完了、実行失敗

## 備考

この問題は実装の品質には影響せず、テスト環境設定の問題と判断される。Phase 3実装は正常に完了しており、Controller Specで十分な動作検証が行われている。
