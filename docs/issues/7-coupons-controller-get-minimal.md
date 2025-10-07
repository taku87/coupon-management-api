# Issue #7: CouponsController GET /api/v1/stores/:store_id/coupons 最小実装

## 背景 / 目的
認証なしでクーポン一覧を返す最小コントローラを実装し、Walking Skeletonの垂直スライスを確認する。
DB→Model→Controller→JSONレスポンスの全層が接続されることを検証する。

- **依存**: #5
- **ラベル**: `backend`, `api`

---

## スコープ / 作業項目

1. `app/controllers/api/v1/coupons_controller.rb` 作成
2. `index` アクション実装
3. routes.rb にルーティング追加
4. curl での動作確認

---

## ゴール / 完了条件（Acceptance Criteria）

- [ ] `app/controllers/api/v1/coupons_controller.rb` 作成
- [ ] `index` アクションで `Store.find(params[:store_id]).coupons` を返す
- [ ] routes.rb にネストしたルーティング追加
- [ ] curl でGET成功（200）
- [ ] レスポンスはJSONで配列を返す

---

## テスト観点

- **ルーティング確認**:
  - `rails routes | grep coupons` でパス確認
- **API確認**:
  - `curl http://localhost:3000/api/v1/stores/1/coupons` で200
  - レスポンスがJSON配列形式

---

## 参照ドキュメント

- [04_api.md](../04_api.md) - エンドポイント一覧（セクション4）
- [02_architecture.md](../02_architecture.md) - レイヤー構成

---

## 実装例

```ruby
# app/controllers/api/v1/coupons_controller.rb
module Api
  module V1
    class CouponsController < ApplicationController
      def index
        store = Store.find(params[:store_id])
        coupons = store.coupons.order(valid_until: :asc, id: :asc)
        render json: coupons
      end
    end
  end
end

# config/routes.rb
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :stores, only: [] do
        resources :coupons, only: [:index, :create]
      end
    end
  end
end
```
