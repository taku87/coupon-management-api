# Issue #8: CouponsController POST /api/v1/stores/:store_id/coupons 最小実装

## 背景 / 目的
認証なしでクーポンを作成できる最小実装を行い、Walking Skeletonの完成を目指す。
作成系APIの基本フローとバリデーションエラーハンドリングを確認する。

- **依存**: #7
- **ラベル**: `backend`, `api`

---

## スコープ / 作業項目

1. `create` アクション実装
2. Strong Parameters 定義
3. 成功時・失敗時のレスポンス実装
4. curl での動作確認

---

## ゴール / 完了条件（Acceptance Criteria）

- [ ] `create` アクションで `Store.find.coupons.create` 実装
- [ ] Strong Parameters で title, discount_percentage, valid_until のみ許可
- [ ] 成功時 201 + created resourceを返す
- [ ] バリデーションエラー時は 422
- [ ] curl でPOST成功確認

---

## テスト観点

- **正常系**:
  - 正しいパラメータで 201 Created
  - レスポンスに作成されたクーポンが含まれる
- **異常系**:
  - title なしで 422
  - discount_percentage 範囲外（0, 101）で 422

---

## 参照ドキュメント

- [04_api.md](../04_api.md) - クーポン作成仕様（セクション7.2）
- [CLAUDE.md](../CLAUDE.md) - 実装ルール

---

## 実装例

```ruby
# app/controllers/api/v1/coupons_controller.rb
def create
  store = Store.find(params[:store_id])
  coupon = store.coupons.build(coupon_params)

  if coupon.save
    render json: coupon, status: :created
  else
    render json: { errors: coupon.errors.full_messages }, status: :unprocessable_entity
  end
end

private

def coupon_params
  params.require(:coupon).permit(:title, :discount_percentage, :valid_until)
end
```
