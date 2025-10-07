# Issue #5: Store/Couponモデル実装

## 背景 / 目的
ActiveRecordモデルを作成し、バリデーション・関連を定義する。
アプリケーション層でのデータ整合性を担保し、DBスキーマと二層防御を実現する。

- **依存**: #4
- **ラベル**: `backend`, `model`

---

## スコープ / 作業項目

1. `app/models/store.rb` 作成
2. `app/models/coupon.rb` 作成
3. バリデーション実装
4. 関連定義（has_many / belongs_to）
5. rails console での動作確認

---

## ゴール / 完了条件（Acceptance Criteria）

- [ ] `app/models/store.rb` に `has_many :coupons` と `validates :name, presence: true`
- [ ] `app/models/coupon.rb` に `belongs_to :store` と全バリデーション実装
- [ ] `validates :title, uniqueness: { scope: :store_id }`
- [ ] `validates :discount_percentage, inclusion: 1..100`
- [ ] rails console で Store.create / Coupon.create が動作

---

## テスト観点

- **バリデーション確認**:
  - `Coupon.new(title: nil).valid?` が false
  - `Coupon.new(discount_percentage: 0).valid?` が false
  - 同一store内で同一titleが invalid
- **関連確認**:
  - `store.coupons` でコレクション取得
  - `coupon.store` で親取得

---

## 参照ドキュメント

- [03_database.md](../03_database.md) - モデル一覧と責務（セクション2）
- [CLAUDE.md](../CLAUDE.md) - コーディング規約

---

## 実装例

```ruby
# app/models/store.rb
class Store < ApplicationRecord
  has_many :coupons, dependent: :destroy

  validates :name, presence: true
end

# app/models/coupon.rb
class Coupon < ApplicationRecord
  belongs_to :store

  validates :title, :discount_percentage, :valid_until, presence: true
  validates :discount_percentage, inclusion: { in: 1..100 }
  validates :title, uniqueness: { scope: :store_id }
end
```
