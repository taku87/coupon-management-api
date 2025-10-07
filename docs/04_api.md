# 04_api.md

## 目的

Coupon 管理用 REST API の**外部仕様**を定義する。
リソース、エンドポイント、認証、入出力フォーマット、ページネーション、エラー仕様を明確化する。
レスポンスは JSON（JSON:API 準拠）で返す。

---

## 1. バージョニング / ベースURL

* ベースパス: `/api/v1`
* 例: `GET /api/v1/stores/:store_id/coupons`

---

## 2. 認証

* スキーム: **JWT (RS256, kid 付)**
* ヘッダー: `Authorization: Bearer <access_token>`
* トークンには `sub`（= store_uid）を含むこと。
* **テナント境界**: `:store_id` はアクセストークンのテナント（= current_store）と一致していなければならない。越境アクセスは禁止。
  （詳細: [05_security.md](./05_security.md)）

---

## 3. リソース（Coupon）

### 3.1 属性定義

| 属性                  | 型                  | 必須 | 説明            |
| ------------------- | ------------------ | -- | ------------- |
| id                  | string             | -  | リソースID        |
| title               | string             | ✔︎ | クーポン名（店舗内で一意） |
| discount_percentage | integer            | ✔︎ | 1〜100         |
| valid_until         | date (YYYY-MM-DD)  | ✔︎ | 有効期限（日付）      |
| created_at          | datetime (ISO8601) | -  | 作成日時          |
| updated_at          | datetime (ISO8601) | -  | 更新日時          |

> スキーマ詳細は [03_database.md](./03_database.md)。
> 現要件は **date** 粒度。将来「翌1時まで」のような要件があれば `valid_until_at: datetime` を検討。

---

## 4. エンドポイント一覧

| メソッド | パス                                 | 概要            | 認証 | テナント不一致時       |
| ---- | ---------------------------------- | ------------- | -- | -------------- |
| GET  | `/api/v1/stores/:store_id/coupons` | 指定店舗のクーポン一覧取得 | 必須 | 403 Forbidden  |
| POST | `/api/v1/stores/:store_id/coupons` | 指定店舗にクーポン新規作成 | 必須 | 403 Forbidden  |

> 注記: `:store_id` は **アクセストークンのテナントと一致**している必要がある。
> 不一致の場合は 403 Forbidden を返す（詳細は [05_security.md](./05_security.md) 参照）。

---

## 5. 共通ヘッダー / コンテンツタイプ

* リクエスト:

  * `Content-Type: application/json`
  * `Accept: application/json`
* レスポンス: JSON:API 風の `data` / `meta` 構造。

---

## 6. ページネーション

* クエリパラメータ:

  * `page[number]` … 1 起点（デフォルト: 1）
  * `page[size]` … 1〜100（デフォルト: 20）
* レスポンスの `meta` にページ情報を含める。

```json
"meta": { "page": 1, "per_page": 20, "count": 57, "pages": 3 }
```

---

## 7. エンドポイント仕様

### 7.1 クーポン一覧

* **GET** `/api/v1/stores/:store_id/coupons`
* 説明: `:store_id` のクーポン一覧を返す。**他店舗のデータは返さない**。
* クエリ:

  * `page[number]` / `page[size]`
  * （将来）`filter[active]=true` … `valid_until >= today` のみを返す
* 成功レスポンス（200 / JSON:API 例）:

```json
{
  "data": [
    {
      "id": "101",
      "type": "coupon",
      "attributes": {
        "title": "10% OFF",
        "discount_percentage": 10,
        "valid_until": "2025-08-31",
        "created_at": "2025-08-01T01:23:45Z",
        "updated_at": "2025-08-01T01:23:45Z"
      }
    }
  ],
  "meta": { "page": 1, "per_page": 20, "count": 57, "pages": 3 }
}
```

* 主なエラー:

  * 401 認証失敗
  * 403 テナント越境
  * 404 店舗未存在

---

### 7.2 クーポン作成

* **POST** `/api/v1/stores/:store_id/coupons`
* リクエストボディ（JSON:API 風）:

```json
{
  "data": {
    "type": "coupon",
    "attributes": {
      "title": "10% OFF",
      "discount_percentage": 10,
      "valid_until": "2025-08-31"
    }
  }
}
```

* 成功レスポンス（201）:

```json
{
  "data": {
    "id": "201",
    "type": "coupon",
    "attributes": {
      "title": "10% OFF",
      "discount_percentage": 10,
      "valid_until": "2025-08-31",
      "created_at": "2025-08-01T03:21:00Z",
      "updated_at": "2025-08-01T03:21:00Z"
    }
  }
}
```

* バリデーションエラー（422）例:

```json
{
  "errors": [{
    "status": "422",
    "code": "validation_error",
    "title": "Validation failed",
    "detail": "discount_percentage must be between 1 and 100",
    "source": { "pointer": "/data/attributes/discount_percentage" }
  }]
}
```

---

## 8. エラー仕様（共通）

エラーレスポンスの詳細仕様・セキュリティ観点・statusコード定義は
[05_security.md](./05_security.md) に記載。

基本形式: JSON:API 風 `errors[]`。属性に関するものは `source.pointer` を付与。

---

## 9. セキュリティ / マルチテナント原則

* すべてのアクセスは**トークンに紐づくテナントのみに限定**。
* `:store_id` はトークンのテナントと一致していなければならない。
* 取得・作成のクエリは**テナントスコープ**で実行されるべき。
  （実装指針や具体ロジックは 05 を参照: [05_security.md](./05_security.md)）

---

## 10. 将来拡張（スコープ外）

* `filter[active]` の正式化
* `PATCH /coupons/:id`（更新）
* `DELETE /coupons/:id`（削除）
* `valid_until_at: datetime` への移行（「翌1時まで」等に対応）
* Rate limit（429）/ 監査ログ / Idempotency-Key（POST）
