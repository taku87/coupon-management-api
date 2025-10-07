# Issue #16: AuthController実装（ログインAPI）

## 背景 / 目的
POST /api/v1/auth/login でJWTを発行し、認証フローを完成させる。
店舗がAPIアクセス用のトークンを取得できる仕組みを提供する。

- **依存**: #9
- **ラベル**: `backend`, `api`

---

## スコープ / 作業項目

1. `app/controllers/api/v1/auth_controller.rb` 作成
2. `login` アクション実装
3. routes.rb にルーティング追加
4. `skip_before_action :authenticate_request!` 設定
5. curl での動作確認

---

## ゴール / 完了条件（Acceptance Criteria）

- [ ] `app/controllers/api/v1/auth_controller.rb` 作成
- [ ] `login` アクションで store_id受取 → JWT発行
- [ ] routes.rb に `post 'auth/login'` 追加
- [ ] レスポンスに `{access_token, token_type, expires_in}` を返す
- [ ] curl でログイン→トークン取得→API呼び出し成功

---

## テスト観点

- **正常系**:
  - 正しいstore_idでトークン発行
  - 発行されたトークンでAPI呼び出し成功
- **異常系**:
  - 存在しないstore_idで 404

---

## 参照ドキュメント

- [04_api.md](../04_api.md) - ログインAPI仕様（セクション5）
- [05_security.md](../05_security.md) - JWT発行仕様

---

## 実装例

```ruby
# app/controllers/api/v1/auth_controller.rb
module Api
  module V1
    class AuthController < ApplicationController
      skip_before_action :authenticate_request!, only: [:login]

      def login
        store = Store.find(params[:store_id])

        payload = {
          sub: store.id.to_s,
          scope: 'coupon:read coupon:write'
        }

        token = JwtService.encode(payload)

        render json: {
          access_token: token,
          token_type: 'Bearer',
          expires_in: 900
        }
      end
    end
  end
end

# config/routes.rb に追加
post 'auth/login', to: 'auth#login'
```

---

## 要確認事項

- ログインAPIの認証方式（store_id のみ？パスワード認証？外部IdP連携？）
