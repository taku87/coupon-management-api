# Issue #13: ApplicationController エラーハンドリング統一

## 背景 / 目的
rescue_from で例外を JSON:API形式に変換し、全APIで統一したエラーレスポンスを実現する。
ユーザーフレンドリーなエラーメッセージと適切なHTTPステータスコードを返却する。

- **依存**: #12
- **ラベル**: `backend`, `error-handling`

---

## スコープ / 作業項目

1. `ApplicationController` に rescue_from 定義
2. 各例外に対応するエラーレスポンス実装
3. JSON:API errors 構造の統一
4. curl での動作確認

---

## ゴール / 完了条件（Acceptance Criteria）

- [ ] `rescue_from ActiveRecord::RecordNotFound` → 404
- [ ] `rescue_from ActiveRecord::RecordInvalid` → 422
- [ ] `rescue_from Pundit::NotAuthorizedError` → 403
- [ ] `rescue_from JWT::VerificationError` → 401（既存実装統合）
- [ ] すべてJSON:API errors構造で返す

---

## テスト観点

- **エラー確認**:
  - 存在しないリソースで 404
  - バリデーションエラーで 422
  - 認可失敗で 403
  - 認証失敗で 401
- **レスポンス形式確認**:
  - `errors: [{status, code, title, detail}]` 形式

---

## 参照ドキュメント

- [05_security.md](../05_security.md) - エラー応答（セクション6）
- [04_api.md](../04_api.md) - エラー仕様（セクション8）

---

## 実装例

```ruby
# app/controllers/application_controller.rb に追加
rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity

private

def render_not_found(exception)
  render json: {
    errors: [{
      status: '404',
      code: 'not_found',
      title: 'Not Found',
      detail: exception.message
    }]
  }, status: :not_found
end

def render_unprocessable_entity(exception)
  render json: {
    errors: [{
      status: '422',
      code: 'validation_error',
      title: 'Validation failed',
      detail: exception.record.errors.full_messages.join(', ')
    }]
  }, status: :unprocessable_entity
end
```
