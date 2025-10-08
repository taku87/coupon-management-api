# 05_security.md

## 目的

本ドキュメントは、クーポン管理 REST API の**セキュリティ設計**（認証・認可・マルチテナント境界・鍵運用・レート制限・監査・運用ポリシー）を定義する。
実装は Ruby on Rails (API mode) を前提とするが、**ここでは方針と契約の境界を明示する**。

---

## 1. スコープ

* 対象: `/api/v1` 配下のすべてのエンドポイント
* 非対象: インフラ構成（WAF / IPS / VPC設定 等）、UIレイヤ、削除API（今回スコープ外）

---

## 2. 認証（Authentication）

### 2.1 トークン仕様

* 方式: **JWT Bearer**（`Authorization: Bearer <token>`）
* 署名: **RS256（公開鍵署名）**
* ヘッダ: `alg=RS256`, `typ=JWT`, **`kid` 必須**
* ペイロード最小構成:

  | クレーム    | 意味                                                            |
  | ------- | ------------------------------------------------------------- |
  | `iss`   | 発行者（例: https://auth.example.com） |
  | `aud`   | 想定受信者（例: coupon-api）                                          |
  | `sub`   | Store 識別子（`store_uid`）                                        |
  | `exp`   | 失効時刻（短命トークンを推奨）                                               |
  | `iat`   | 発行時刻                                                          |
  | `jti`   | トークン一意ID（リプレイ防止）                                              |
  | `scope` | 権限（例: `"coupon:read coupon:write"` スペース区切り文字列、OAuth2 RFC 6749準拠） |

#### 検証項目

1. 署名（`kid` に対応する公開鍵で検証）
2. `iss`, `aud` 一致
3. `exp`, `iat` 妥当（±60秒の clock skew 許容）
4. `sub` の存在確認（＝ current_store の識別子）
5. `scope` に操作権限が含まれること

> **Access Token 有効期限:** 5〜15分を推奨（Refreshはスコープ外）

---

### 2.2 鍵管理・ローテーション

* **開発環境:** `.env` に秘密鍵を定義（ローカル限定）
* **本番環境:** AWS Secrets Manager 等で秘密鍵管理。アプリ側は公開鍵のみ保持。
* **ローテーション:** `kid` により新旧鍵を並行稼働 → 新鍵配信後、旧鍵を失効。
* 鍵漏洩対応:

  1. 新鍵発行・`kid` 更新
  2. 旧鍵を失効
  3. 影響範囲ログを `jti`/`sub` で検索
  4. 必要に応じ一時 denylist 運用

---

## 3. 認可（Authorization）とマルチテナント境界

### 3.1 クエリガード（必須規約）

* **すべてのデータアクセスは `current_store` 起点。**

  * ✅ `current_store.coupons.find(params[:id])`
  * ❌ `Coupon.find(params[:id])`
* Controller では `:store_id` と `current_store.id` の一致を検証。
* Policy 層でも `store_id` によるスコープ制限を再度実施（**二重防御**）。

### 3.2 Policy（scope）

* `scope` の例: `coupon:read`, `coupon:write`
* 操作別に最低限のスコープを要求：

  | 操作            | 必要スコープ       |
  | ------------- | ------------ |
  | GET /coupons  | coupon:read  |
  | POST /coupons | coupon:write |
* 管理者・運営者など上位権限はスコープのスーパーセットとして将来拡張。

### 3.3 DBレイヤの境界

* `store_id` は NOT NULL + FK制約必須。
* UNIQUE `(store_id, title)` によりテナント内一意性を担保。
* 将来的には PostgreSQL **RLS (Row Level Security)** による強制分離も検討。

### 3.4 テスト観点

テスト仕様・観点の詳細は [06_testing.md](./06_testing.md) を参照。

---

## 4. レート制限 / アンチアビューズ

| 区分         | 制御単位             | 推奨閾値          | 備考            |
| ---------- | ---------------- | ------------- | ------------- |
| 一般リクエスト    | IP               | 200 req/min   | 通常利用対策        |
| 店舗単位       | `sub`（store_uid） | 600 req/10min | テナント単位のスパイク防止 |
| 作成系 (POST) | `sub`            | 60 req/10min  | ボット対策         |

その他の防御策:

* **`page[size]` 上限 100**（超過は400または自動丸め）
* **JSONボディ上限 1MB**（過大入力防止）
* **`title` 長さ上限 100文字**、`discount_percentage` 範囲 1〜100
* 今後必要に応じ **`Idempotency-Key` ヘッダ**を導入（POST重複防止）

---

## 5. 監査ログ / 可観測性

### 5.1 監査ログ（PII最小化）

* 記録項目:

  * `timestamp`, `method`, `path`, `status`, `duration_ms`,
    `store_uid(sub)`, `jti`, `client_ip`, `user_agent`
* ボディ内容は記録しない（個人情報リスク回避）
* **4xx/5xx多発時はアラート化**


## 6. エラー応答（全API共通契約）

全APIで統一したエラーレスポンス形式を定義する。

### 6.1 ステータスコード定義

| ステータス | 事象                    | 説明                      |
| ----- | --------------------- | ----------------------- |
| 400   | Bad Request           | JSON 形式不正など             |
| 401   | Unauthorized          | トークン署名不正、期限切れ、`iss/aud` 不一致 |
| 403   | Forbidden             | テナント越境、scope 不足、権限不足     |
| 404   | Not Found             | リソース未存在               |
| 409   | Conflict              | 一意制約違反（例: 同一タイトル）       |
| 422   | Unprocessable Entity  | バリデーションエラー            |
| 429   | Too Many Requests     | レート制限超過               |
| 500   | Internal Server Error | 鍵検証失敗・想定外例外（内部ログのみ詳細保持） |

### 6.2 レスポンス形式

JSON:API 準拠の `errors[]` 構造を利用。属性に関するものは `source.pointer` を付与。

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

## 7. CORS / 通信

* すべて **HTTPS** 強制（HSTS 推奨）
* **CORSポリシー**:
  * **想定利用形態**: パートナーのバックエンドサーバーからの呼び出し（サーバー間通信）
  * サーバー間通信ではCORS制約が適用されないため、**デフォルトではCORS設定不要**
  * 将来的にブラウザからの直接アクセス（SPA構成）が必要になった場合のみ有効化を検討
  * 有効化する場合: 許可オリジンを環境変数で明示列挙（`*` 禁止）
  * 許可ヘッダ: `Authorization`, `Content-Type`
* TLS: 強度要件を満たす暗号スイートのみ許可（インフラ側で統制）

> **注記**: CORS設定の要否については [DISCUSSION.md](../DISCUSSION.md) の「クライアントアプリケーションのアーキテクチャとCORS設定の要否」を参照。

---

## 8. 安全実装チェックリスト

* ✅ **返却属性はホワイトリスト化**（Serializer側で明示）
* ✅ **例外の握り潰し禁止**（500→汎用メッセージに変換）
* ✅ **Strong Parameters**によるキー制御
* ✅ **Pagination**の上限強制
* ✅ **環境変数はSecrets Manager等から注入**
* ✅ **current_storeスコープ以外でのクエリ禁止**（`Coupon.find` 禁止）


## 9. 運用・手順（要約）

1. **鍵ローテ計画**：新鍵作成 → `kid`配布 → 並行運用 → 旧鍵失効
2. **秘密管理**：本番はSecrets Manager、ローカルのみ `.env`
3. **レート制限閾値チューニング**：アラートを監視運用とセットで回す
4. **監査ログ可視化**：メトリクス・ダッシュボード化
5. **定期脆弱性スキャン / ライブラリアップデート**

## 10. メンバー確認事項

* 管理者が**越境参照**を行う運用を想定するか
  → あり得る場合は別ドメイン / 権限分離で設計
* **監査ログ保管期間**と**開示要件**
* **レート制限 閾値**の初期設定と例外処理フロー
* **鍵漏洩 / DoS** 発生時の対応体制・連絡系統
