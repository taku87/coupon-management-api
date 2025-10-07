# Issue #10: ApplicationController に JWT認証機能追加

## 背景 / 目的
before_action で JWT検証を行い、current_store を設定する。
全APIエンドポイントで認証を強制し、テナントコンテキストを確立する。

- **依存**: #9
- **ラベル**: `backend`, `security`

---

## スコープ / 作業項目

1. `ApplicationController` に `authenticate_request!` 実装
2. `current_store` メソッド実装
3. 認証失敗時の 401 レスポンス実装
4. CouponsController で before_action 追加（継承で自動適用）
5. curl での動作確認

---

## ゴール / 完了条件（Acceptance Criteria）

- [ ] `authenticate_request!` メソッドで Authorization Bearer トークン検証
- [ ] `current_store` を @current_store にキャッシュ
- [ ] 認証失敗時に 401 Unauthorized を返す
- [ ] CouponsController で `before_action :authenticate_request!` が継承される
- [ ] curl で無トークンアクセス → 401 確認

---

## テスト観点

- **認証成功**:
  - 有効なトークンで API アクセス可能
  - `current_store` が正しく設定される
- **認証失敗**:
  - トークンなしで 401
  - 無効トークンで 401
  - exp 超過で 401

---

## 参照ドキュメント

- [05_security.md](../05_security.md) - 認証仕様（セクション2）
- [04_api.md](../04_api.md) - 認証ヘッダー仕様

---

## 実装例

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  before_action :authenticate_request!

  attr_reader :current_store

  private

  def authenticate_request!
    token = extract_token_from_header
    payload = JwtService.decode(token)
    @current_store = Store.find_by!(id: payload['sub'])
  rescue JWT::VerificationError, JWT::ExpiredSignature, ActiveRecord::RecordNotFound
    render json: { errors: [{ status: '401', code: 'unauthorized', title: 'Unauthorized' }] }, status: :unauthorized
  end

  def extract_token_from_header
    header = request.headers['Authorization']
    header&.split(' ')&.last
  end
end
```
