# Issue #14: CouponSerializer実装（JSON:API準拠）

## 背景 / 目的
jsonapi-serializer でクーポンレスポンスを整形し、JSON:API仕様に準拠した統一フォーマットを実現する。
クライアント側での解析を容易にし、API仕様の一貫性を保つ。

- **依存**: #3
- **ラベル**: `backend`, `api`

---

## スコープ / 作業項目

1. `app/serializers/coupon_serializer.rb` 作成
2. attributes 定義
3. CouponsController で Serializer 使用
4. curl でレスポンス確認

---

## ゴール / 完了条件（Acceptance Criteria）

- [ ] `app/serializers/coupon_serializer.rb` 作成
- [ ] attributes: id, title, discount_percentage, valid_until, created_at, updated_at
- [ ] CouponsController#index/create でSerializerを使用
- [ ] レスポンスが `{data: [{id, type, attributes}]}` 形式
- [ ] curl でフォーマット確認

---

## テスト観点

- **レスポンス形式**:
  - `data` キーが存在
  - `type: "coupon"` が含まれる
  - `attributes` に全フィールドが含まれる

---

## 参照ドキュメント

- [04_api.md](../04_api.md) - レスポンス仕様（セクション7）
- [02_architecture.md](../02_architecture.md) - jsonapi-serializer採択理由

---

## 実装例

```ruby
# app/serializers/coupon_serializer.rb
class CouponSerializer
  include JSONAPI::Serializer

  attributes :title, :discount_percentage, :valid_until, :created_at, :updated_at
end

# app/controllers/api/v1/coupons_controller.rb
def index
  coupons = current_store.coupons.order(valid_until: :asc, id: :asc)
  render json: CouponSerializer.new(coupons).serializable_hash
end

def create
  coupon = current_store.coupons.build(coupon_params)
  authorize coupon

  if coupon.save
    render json: CouponSerializer.new(coupon).serializable_hash, status: :created
  else
    render json: { errors: coupon.errors.full_messages }, status: :unprocessable_entity
  end
end
```
