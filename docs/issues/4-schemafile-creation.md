# Issue #4: Schemafile作成（Store/Coupon）

## 背景 / 目的
ridgepoleによる宣言的スキーマ管理を開始し、stores・couponsテーブルを定義する。
DB制約（FK・UNIQUE・CHECK）をコードとして管理し、レビュー可能な状態にする。

- **依存**: #3
- **ラベル**: `backend`, `database`

---

## スコープ / 作業項目

1. `db/Schemafile` 作成
2. stores テーブル定義
3. coupons テーブル定義（FK・制約含む）
4. ridgepole --apply 実行
5. DB接続確認

---

## ゴール / 完了条件（Acceptance Criteria）

- [ ] `db/Schemafile` に stores テーブル定義（id, name, timestamps）
- [ ] coupons テーブル定義（id, store_id, title, discount_percentage, valid_until, timestamps）
- [ ] FK制約・UNIQUE制約・CHECK制約（discount 1-100）を記述
- [ ] `bundle exec ridgepole -c config/database.yml -E development -f db/Schemafile --apply` 成功
- [ ] `rails dbconsole` でテーブル存在確認

---

## テスト観点

- **スキーマ確認**:
  - `\dt` でstores・coupons存在確認
  - `\d coupons` でFK・制約確認
- **制約確認**:
  - discount_percentage に CHECK制約が存在
  - (store_id, title) に UNIQUE制約が存在

---

## 参照ドキュメント

- [03_database.md](../03_database.md) - スキーマ仕様（セクション3）
- [02_architecture.md](../02_architecture.md) - ridgepole採択理由

---

## 実装例

```ruby
# db/Schemafile
create_table "stores", force: :cascade do |t|
  t.string "name", null: false
  t.timestamps
end

create_table "coupons", force: :cascade do |t|
  t.bigint "store_id", null: false
  t.string "title", null: false
  t.integer "discount_percentage", null: false
  t.date "valid_until", null: false
  t.timestamps

  t.index ["store_id"], name: "index_coupons_on_store_id"
  t.index ["store_id", "title"], name: "index_coupons_on_store_id_and_title", unique: true
  t.index ["store_id", "valid_until"], name: "index_coupons_on_store_id_and_valid_until"
end

add_foreign_key "coupons", "stores", on_delete: :cascade

execute <<-SQL
  ALTER TABLE coupons
  ADD CONSTRAINT check_discount_percentage
  CHECK (discount_percentage BETWEEN 1 AND 100)
SQL
```
