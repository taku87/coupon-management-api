# 03_database.md

## 目的

本ドキュメントでは、データモデルとスキーマ設計を示す。
対象は Store と Coupon の2モデル。**制約・インデックス・外部キー・整合性方針**を明確にし、実装と運用で一貫性を保つ。

---

## 1. ER 図（Mermaid）

```mermaid
erDiagram
    STORE ||--o { COUPON : has_many
    STORE {
        bigint id PK
        string name "店舗名 (NOT NULL)"
        datetime created_at
        datetime updated_at
    }
    COUPON {
        bigint id PK
        bigint store_id FK "stores.id"
        string title "クーポン名 (NOT NULL)"
        integer discount_percentage "割引率 (1〜100)"
        date valid_until "有効期限 (日付)"
        datetime created_at
        datetime updated_at
    }
```

---

## 2. モデル一覧と責務

### Store

* 役割: 店舗の基本情報
* 関連: `has_many :coupons`
* 主な制約: `name` の存在

### Coupon

* 役割: 店舗に紐づくクーポン情報
* 関連: `belongs_to :store`
* 主な制約:

  * `title` の存在・店舗内一意
  * `discount_percentage` が 1〜100
  * `valid_until` の存在（日付）

---

## 3. スキーマ仕様（ridgepole 管理）

このスキーマは ridgepole（Schemafile）で宣言的に管理する。
以下は論理仕様と、代表的な Schemafile 抜粋。

### stores テーブル

| カラム        | 型        | null | 補足               |
| ---------- | -------- | ---- | ---------------- |
| id         | bigint   | no   | 主キー              |
| name       | string   | no   | 店舗名              |
| created_at | datetime | no   | Rails timestamps |
| updated_at | datetime | no   | Rails timestamps |

* 推奨インデックス: なし（将来の検索要件に応じて追加）
* アプリ制約: `validates :name, presence: true`

---

### coupons テーブル

| カラム                 | 型        | null | 補足               |
| ------------------- | -------- | ---- | ---------------- |
| id                  | bigint   | no   | 主キー              |
| store_id            | bigint   | no   | FK: `stores.id`  |
| title               | string   | no   | クーポン名（同一店舗内で一意）  |
| discount_percentage | integer  | no   | 1〜100（DBチェックあり）  |
| valid_until         | date     | no   | 有効期限（日付）         |
| created_at          | datetime | no   | Rails timestamps |
| updated_at          | datetime | no   | Rails timestamps |

**インデックス**

* `index_coupons_on_store_id`
* `index_coupons_on_store_id_and_title`（UNIQUE）
* `index_coupons_on_store_id_and_valid_until`
* （将来）部分インデックス `WHERE valid_until >= CURRENT_DATE`

**外部キー**

* `fk_coupons_store_id → stores.id ON DELETE CASCADE`

**チェック制約**

* `discount_percentage BETWEEN 1 AND 100`

**アプリ制約**

* `validates :title, :discount_percentage, :valid_until, :store, presence: true`
* `validates :discount_percentage, inclusion: 1..100`
* `validates :title, uniqueness: { scope: :store_id }`

**バリデーション方針**

* `valid_until` の過去日付チェックは実装しない（論理上は許容）
  * 理由: 過去のクーポンも記録として残す運用を想定
  * 業務要件として「過去のクーポンを記録として保持する」ことを許容する

---

## 4. 削除ポリシー

> 今回のスコープに削除機能は含まれないため、削除ポリシーの詳細設計は行わない。
> 将来的に削除操作を実装する際には、DBレベルの外部キー設定（`ON DELETE CASCADE`）と
> Rails側の `dependent: :destroy` / `:delete_all` の整合性を検討する。

---

## 5. 時間と日付の扱い

**方針**

`valid_until` は **date 型**（タイムゾーン非依存）を採用する。
要件上「有効期限（日付）」として定義されており、
「2025-08-31 まで有効」といった“日単位”の有効範囲を表現できれば十分である。

**理由**

1. **要件の粒度が「日」単位であるため**
   現時点では「◯時まで有効」などの時間指定は要件に含まれていない。
   `date` 型でシンプルかつ誤解のない実装が可能。
2. **比較ロジックが単純で安全**
   `valid_until >= Date.current` により、一貫した日付比較ができる。
   タイムゾーンの影響を受けず、日付跨ぎの off-by-one エラーを防げる。
3. **API設計・テストがシンプル**
   入出力ともに `YYYY-MM-DD` フォーマット（ISO8601）で統一できるため、
   クライアント側でも扱いやすい。

**将来の拡張可能性への配慮**

将来的に営業時間が「翌1時まで」など、時刻単位での有効性管理が必要になる可能性を考慮し、
以下の設計上の配慮を行う。

* 日付比較ロジックをモデル層のメソッド（例：`Coupon#active?`）に集約しておく
  → 後から date → datetime に変更しても影響範囲を局所化できる
* SerializerやSchema定義上に「日付単位での有効期限」と明記し、
  型拡張が発生してもAPI契約の整合性を保ちやすくする

> 注記: 時刻単位の有効性管理が必要になった場合は、`valid_until_at: datetime` への移行を検討する

---

## 6. 一覧取得と最適化方針

* 既定並び順: `valid_until ASC, id ASC`
* クエリ例

  * 全件: `current_store.coupons.order(valid_until: :asc, id: :asc)`
  * 有効クーポンのみ: `current_store.coupons.where("valid_until >= ?", Date.current).order(valid_until: :asc, id: :asc)`
* インデックス `(store_id, valid_until)` により効率化
* 頻繁に「有効のみ」を取得する場合、部分インデックスを導入

---

## 7. サンプルデータ（seed）

```ruby
# db/seeds.rb
store = Store.create!(name: "Sample Store")

store.coupons.create!(
  title: "10% OFF",
  discount_percentage: 10,
  valid_until: Date.current.end_of_month
)

store.coupons.create!(
  title: "Summer Sale",
  discount_percentage: 20,
  valid_until: Date.current.next_month.end_of_month
)
```

---

## 8. マルチテナント安全性

* **一意性:** `(store_id, title)` で UNIQUE
* **クエリガード:** すべてのアクセスは `current_store.coupons` 起点（`Coupon.find` 禁止）
* **将来的選択肢:** PostgreSQL Row-Level Security (RLS) により
  `store_id = current_setting('app.current_store_id')` の制約も検討可

> クエリ規約の詳細は [05_security.md](./05_security.md) を参照。

---

## 9. 設計上の意図

* 要件に忠実な最小スキーマ
* アプリ側バリデーション＋DB制約の **二層防御設計**
* date 型採用により、タイムゾーン差を排除しつつ拡張余地を残す
* `(store_id, valid_until)` 複合インデックスで現実的な性能を確保
* ridgepole によるスキーマ宣言管理でレビュー性・再現性を担保
  （詳細は [02_architecture.md](./02_architecture.md) 参照）

