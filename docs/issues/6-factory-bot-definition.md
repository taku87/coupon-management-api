# Issue #6: FactoryBot定義（Store/Coupon）

## 背景 / 目的
RSpecテストで使用するテストデータ生成ファクトリを定義する。
再現性のあるテストデータを簡潔に生成し、テスト実装を効率化する。

- **依存**: #5
- **ラベル**: `backend`, `test`

---

## スコープ / 作業項目

1. `spec/factories/stores.rb` 作成
2. `spec/factories/coupons.rb` 作成
3. デフォルト値設定（特に valid_until）
4. rails console での動作確認

---

## ゴール / 完了条件（Acceptance Criteria）

- [ ] `spec/factories/stores.rb` で `:store` ファクトリ定義
- [ ] `spec/factories/coupons.rb` で `:coupon` ファクトリ定義（store関連含む）
- [ ] `valid_until` はデフォルトで未来日付を生成
- [ ] rails console で `FactoryBot.create(:coupon)` が成功

---

## テスト観点

- **ファクトリ確認**:
  - `FactoryBot.create(:store)` が正常実行
  - `FactoryBot.create(:coupon)` が store 付きで生成
  - `FactoryBot.build(:coupon).valid?` が true

---

## 参照ドキュメント

- [06_testing.md](../06_testing.md) - テストデータ方針（セクション3）
- [03_database.md](../03_database.md) - バリデーション方針

---

## 実装例

```ruby
# spec/factories/stores.rb
FactoryBot.define do
  factory :store do
    name { "Test Store" }
  end
end

# spec/factories/coupons.rb
FactoryBot.define do
  factory :coupon do
    store
    title { "10% OFF" }
    discount_percentage { 10 }
    valid_until { Date.current.next_month.end_of_month }
  end
end
```
