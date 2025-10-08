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
3. `page` / `limit` パラメータ対応
4. レスポンスに meta 情報追加
5. curl での動作確認

---

## ゴール / 完了条件（Acceptance Criteria）

- [ ] `config/initializers/pagy.rb` 作成（デフォルト20件、最大100件）
- [ ] CouponsController#index で `pagy(current_store.coupons)` 適用
- [ ] `page` / `limit` パラメータ対応
- [ ] レスポンスに `meta: {current_page, per_page, total_count, total_pages}` を追加
- [ ] curl で `?limit=5&page=2` 動作確認

---

## テスト観点

- **ページネーション確認**:
  - デフォルトで20件取得
  - `limit` で件数変更
  - `page` でページ変更
  - meta 情報が正しい

---

## 参照ドキュメント

- [04_api.md](../04_api.md) - ページネーション仕様（セクション6）
- [02_architecture.md](../02_architecture.md) - Pagy採択理由

---

## 実装例

```ruby
# config/initializers/pagy.rb
require 'pagy/extras/overflow'
require 'pagy/extras/limit'

Pagy::DEFAULT[:limit] = 20
Pagy::DEFAULT[:limit_max] = 100
Pagy::DEFAULT[:limit_param] = :limit
Pagy::DEFAULT[:overflow] = :last_page

# app/controllers/application_controller.rb
include Pagy::Backend

# app/controllers/api/v1/coupons_controller.rb
def index
  coupons = current_store.coupons
  pagy, paginated_coupons = pagy(coupons)

  render json: CouponSerializer.new(paginated_coupons).serializable_hash.merge(
    meta: pagination_meta(pagy)
  )
end

def pagination_meta(pagy)
  {
    current_page: pagy.page,
    total_pages: pagy.pages,
    total_count: pagy.count,
    per_page: pagy.limit
  }
end
```

---

## 要確認事項

- `limit` 上限100超過時の挙動（自動丸めで100に制限）
