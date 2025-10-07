# Issue #11: Pundit導入・CouponPolicy実装

## 背景 / 目的
Punditを導入し、CouponPolicyでテナント境界制御を実装する。
認証（誰か）と認可（何ができるか）を分離し、scope検証を行う。

- **依存**: #10
- **ラベル**: `backend`, `security`

---

## スコープ / 作業項目

1. Pundit インストール・初期化
2. `app/policies/coupon_policy.rb` 作成
3. `index?` / `create?` メソッド実装
4. scope 検証ロジック実装
5. CouponsController で `authorize` 呼び出し
6. curl での動作確認

---

## ゴール / 完了条件（Acceptance Criteria）

- [ ] `rails g pundit:install` 実行
- [ ] `app/policies/coupon_policy.rb` 作成
- [ ] `index?` / `create?` でテナント境界検証実装
- [ ] CouponsControllerで `authorize` 呼び出し
- [ ] 他店舗クーポンへのアクセスで 403 Forbidden
- [ ] scope検証（`coupon:read` / `coupon:write`）実装

**→ 完了後すぐに #19 (Policy Spec実装) を実施**

---

## テスト観点

- **認可成功**:
  - 自店舗クーポンで index? / create? が true
  - 適切な scope で操作可能
- **認可失敗**:
  - 他店舗クーポンで 403
  - scope 不足（read のみで create）で 403

---

## 参照ドキュメント

- [05_security.md](../05_security.md) - 認可・Policy仕様（セクション3）
- [02_architecture.md](../02_architecture.md) - 認可層の責務

---

## 実装例

```ruby
# app/policies/coupon_policy.rb
class CouponPolicy < ApplicationPolicy
  def index?
    has_scope?('coupon:read')
  end

  def create?
    record.store_id == user.id && has_scope?('coupon:write')
  end

  private

  def has_scope?(required_scope)
    return true unless user.respond_to?(:scopes)
    user_scopes = user.scopes || []
    user_scopes.include?(required_scope)
  end
end

# app/controllers/application_controller.rb に追加
include Pundit::Authorization

rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

private

def user_not_authorized
  render json: { errors: [{ status: '403', code: 'forbidden', title: 'Forbidden' }] }, status: :forbidden
end
```
