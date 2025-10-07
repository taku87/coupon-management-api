# Issue #17: Model Spec実装（Store/Coupon）

## 背景 / 目的
RSpecでモデルのバリデーション・関連テストを実装し、データ整合性を自動検証する。
モデル層の正確性を担保し、リグレッション防止を実現する。

**※ #6 (FactoryBot定義) 完了直後に実施。モデル実装とテストをセットで完結させる**

- **依存**: #6
- **ラベル**: `backend`, `test`

---

## スコープ / 作業項目

1. `spec/models/store_spec.rb` 作成
2. `spec/models/coupon_spec.rb` 作成
3. バリデーションテスト実装
4. 関連テスト実装
5. rspec 実行確認

---

## ゴール / 完了条件（Acceptance Criteria）

- [ ] `spec/models/store_spec.rb` で name必須テスト
- [ ] `spec/models/coupon_spec.rb` で全バリデーションテスト
- [ ] discount_percentage範囲外（0,101）で invalid
- [ ] title一意制約（同一store内）テスト
- [ ] `bundle exec rspec spec/models` 全グリーン

---

## テスト観点

- **バリデーション**:
  - 必須項目が nil で invalid
  - 範囲外の値で invalid
  - 一意制約違反で invalid
- **関連**:
  - has_many / belongs_to が正常動作

---

## 参照ドキュメント

- [06_testing.md](../06_testing.md) - モデル単体テスト観点（セクション4）
- [03_database.md](../03_database.md) - バリデーション方針

---

## 実装例

```ruby
# spec/models/store_spec.rb
require 'rails_helper'

RSpec.describe Store, type: :model do
  describe 'バリデーション' do
    it 'name が必須' do
      store = Store.new(name: nil)
      expect(store).not_to be_valid
      expect(store.errors[:name]).to include("can't be blank")
    end
  end

  describe '関連' do
    it 'has_many :coupons' do
      expect(Store.reflect_on_association(:coupons).macro).to eq(:has_many)
    end
  end
end

# spec/models/coupon_spec.rb
require 'rails_helper'

RSpec.describe Coupon, type: :model do
  describe 'バリデーション' do
    let(:store) { create(:store) }

    it 'title が必須' do
      coupon = Coupon.new(title: nil, store: store, discount_percentage: 10, valid_until: Date.current)
      expect(coupon).not_to be_valid
    end

    it 'discount_percentage が 1〜100 の範囲内' do
      coupon = build(:coupon, discount_percentage: 0)
      expect(coupon).not_to be_valid

      coupon.discount_percentage = 101
      expect(coupon).not_to be_valid

      coupon.discount_percentage = 50
      expect(coupon).to be_valid
    end

    it 'title が同一store内で一意' do
      create(:coupon, title: 'Test', store: store)
      duplicate = build(:coupon, title: 'Test', store: store)
      expect(duplicate).not_to be_valid
    end
  end
end
```
