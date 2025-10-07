# Issue #22: db/seeds.rb 作成（初期データ）

## 背景 / 目的
開発・デモ用のサンプルデータを生成し、ローカル環境での動作確認を容易にする。
過去/未来のクーポンを含む多様なデータで、実運用に近い環境を構築する。

- **依存**: #5
- **ラベル**: `backend`, `data`

---

## スコープ / 作業項目

1. `db/seeds.rb` にStore作成処理追加
2. Coupon複数作成処理追加
3. 過去/未来の valid_until 設定
4. `rails db:seed` 実行確認

---

## ゴール / 完了条件（Acceptance Criteria）

- [ ] `db/seeds.rb` に Store作成・Coupon複数作成を記述
- [ ] `rails db:seed` で正常実行
- [ ] 実行後に rails console で Store.count / Coupon.count 確認
- [ ] valid_until が過去/未来の両方を含む

---

## テスト観点

- **データ確認**:
  - Store が作成される
  - Coupon が複数作成される
  - 過去日付・未来日付の両方が存在

---

## 参照ドキュメント

- [03_database.md](../03_database.md) - サンプルデータ（セクション7）

---

## 実装例

```ruby
# db/seeds.rb
puts "Seeding data..."

# Store作成
store1 = Store.create!(name: "Sample Store 1")
store2 = Store.create!(name: "Sample Store 2")

puts "Created #{Store.count} stores"

# Store1のクーポン
store1.coupons.create!([
  {
    title: "10% OFF",
    discount_percentage: 10,
    valid_until: Date.current.end_of_month
  },
  {
    title: "Summer Sale",
    discount_percentage: 20,
    valid_until: Date.current.next_month.end_of_month
  },
  {
    title: "Past Coupon",
    discount_percentage: 15,
    valid_until: Date.current.prev_month.end_of_month
  }
])

# Store2のクーポン
store2.coupons.create!([
  {
    title: "Winter Campaign",
    discount_percentage: 30,
    valid_until: Date.current + 90.days
  },
  {
    title: "Early Bird",
    discount_percentage: 5,
    valid_until: Date.current + 7.days
  }
])

puts "Created #{Coupon.count} coupons"
puts "Seeding completed!"
```
