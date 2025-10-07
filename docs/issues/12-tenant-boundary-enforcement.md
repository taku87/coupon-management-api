# Issue #12: テナント境界強制（current_storeスコープ）

## 背景 / 目的
すべてのクエリを `current_store.coupons` 起点に変更し、Coupon.find 禁止を徹底する。
マルチテナント境界を物理的に強制し、越境アクセスを根本から防止する。

- **依存**: #11
- **ラベル**: `backend`, `security`

---

## スコープ / 作業項目

1. CouponsController#index を `current_store.coupons` 起点に変更
2. CouponsController#create を `current_store.coupons.create` 起点に変更
3. `:store_id` パラメータと `current_store.id` の一致検証
4. 不一致時の 403 レスポンス実装
5. コードレビューで `Coupon.find` 不使用確認

---

## ゴール / 完了条件（Acceptance Criteria）

- [ ] CouponsController#index を `current_store.coupons` に変更
- [ ] CouponsController#create を `current_store.coupons.create` に変更
- [ ] `:store_id` パラメータと `current_store.id` の一致検証を追加
- [ ] 不一致時に 403 を返す
- [ ] コードレビューで `Coupon.find` が存在しないことを確認

---

## テスト観点

- **正常系**:
  - 自店舗への正常アクセス
  - `current_store.coupons` でスコープされたクエリ
- **異常系**:
  - 他店舗の store_id 指定で 403
  - URL 改ざんで越境アクセス試行 → 403

---

## 参照ドキュメント

- [05_security.md](../05_security.md) - クエリガード（セクション3.1）
- [CLAUDE.md](../CLAUDE.md) - クエリガード厳守

---

## 実装例

```ruby
# app/controllers/api/v1/coupons_controller.rb
class Api::V1::CouponsController < ApplicationController
  before_action :verify_store_access

  def index
    coupons = current_store.coupons.order(valid_until: :asc, id: :asc)
    render json: coupons
  end

  def create
    coupon = current_store.coupons.build(coupon_params)
    authorize coupon

    if coupon.save
      render json: coupon, status: :created
    else
      render json: { errors: coupon.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def verify_store_access
    unless params[:store_id].to_i == current_store.id
      render json: { errors: [{ status: '403', code: 'forbidden', title: 'Forbidden' }] }, status: :forbidden
    end
  end

  def coupon_params
    params.require(:coupon).permit(:title, :discount_percentage, :valid_until)
  end
end
```
