# Issue #15: Pagy導入・ページネーション実装

## 背景 / 目的
GET一覧にPagyを適用し、メタ情報を返す。
大量データの効率的な取得とクライアント側でのページング制御を実現する。

- **依存**: #14
- **ラベル**: `backend`, `api`

---

## スコープ / 作業項目

1. `config/initializers/pagy.rb` 作成
2. CouponsController#index で pagy 適用
3. `page[number]` / `page[size]` パラメータ対応
4. レスポンスに meta 情報追加
5. curl での動作確認

---

## ゴール / 完了条件（Acceptance Criteria）

- [ ] `config/initializers/pagy.rb` 作成（デフォルト20件、最大100件）
- [ ] CouponsController#index で `pagy(current_store.coupons)` 適用
- [ ] `page[number]` / `page[size]` パラメータ対応
- [ ] レスポンスに `meta: {page, per_page, count, pages}` を追加
- [ ] curl で `?page[size]=5&page[number]=2` 動作確認

---

## テスト観点

- **ページネーション確認**:
  - デフォルトで20件取得
  - `page[size]` で件数変更
  - `page[number]` でページ変更
  - meta 情報が正しい

---

## 参照ドキュメント

- [04_api.md](../04_api.md) - ページネーション仕様（セクション6）
- [02_architecture.md](../02_architecture.md) - Pagy採択理由

---

## 実装例

```ruby
# config/initializers/pagy.rb
require 'pagy/extras/items'

Pagy::DEFAULT[:items] = 20
Pagy::DEFAULT[:max_items] = 100

# app/controllers/application_controller.rb
include Pagy::Backend

# app/controllers/api/v1/coupons_controller.rb
def index
  pagy, coupons = pagy(current_store.coupons.order(valid_until: :asc, id: :asc),
                       items: params.dig(:page, :size) || 20,
                       page: params.dig(:page, :number) || 1)

  render json: CouponSerializer.new(coupons).serializable_hash.merge(
    meta: {
      page: pagy.page,
      per_page: pagy.items,
      count: pagy.count,
      pages: pagy.pages
    }
  )
end
```

---

## 要確認事項

- `page[size]` 上限100超過時の挙動（400エラー or 自動丸め）
