了解です。
ここまでの流れ（要件→設計→API仕様→セキュリティ）を踏まえると、
`06_testing.md` は **「テスト観点整理書」** として位置づけるのが最も自然です。

つまり、RSpecコードを書くのではなく、
**どの観点をどの粒度でテストすべきか** を明確にしたドキュメントにします。

---

# 06_testing.md

## 目的

本ドキュメントでは、クーポン管理 REST API の**テスト方針・観点・優先度**を定義する。
RSpec等による自動テスト実装を前提に、**どの範囲を・どの目的で検証すべきか**を明確にする。

---

## 1. テスト全体方針

| 区分        | 方針                                                |
| --------- | ------------------------------------------------- |
| **目的**    | バグ検出よりも、API契約・データ整合・セキュリティ境界の保証を重視する。             |
| **単位**    | RSpec による自動テストを主軸とし、単体・統合・リクエストレベルを明確に分離する。       |
| **データ**   | FactoryBot により再現性あるテストデータを生成。                     |
| **スキーマ**  | Ridgepole で定義された Schemafile をテスト環境に適用し、DB構造を正とする。 |
| **失敗許容度** | 外部依存を排除し、全テストがCI環境で再現可能であること。                     |

---

## 2. テストレイヤー構成

| レイヤー                   | 目的                   | 主対象                          | 実装例                                    |
| ---------------------- | -------------------- | ---------------------------- | -------------------------------------- |
| **Model Spec**         | バリデーション・関連・制約の単体検証   | Store / Coupon               | `spec/models/coupon_spec.rb`           |
| **Request Spec**       | API I/O（入力→出力）の契約保証  | `/api/v1/stores/:id/coupons` | `spec/requests/api/v1/coupons_spec.rb` |
| **Policy Spec**        | 認可（権限制御）ロジック検証       | CouponPolicy                 | `spec/policies/coupon_policy_spec.rb`  |
| **Service Spec**       | JWT発行・認証サービスなど共通処理検証 | JwtService                   | `spec/services/jwt_service_spec.rb`    |
| **System/Integration** | 実際のAPIフロー・例外ハンドリング   | store + coupon CRUD          | `spec/integration/api_flow_spec.rb`    |

---

## 3. テストデータ方針（FactoryBot）

| Factory   | 主な属性                                                   | 依存    |
| --------- | ------------------------------------------------------ | ----- |
| `:store`  | `name`                                                 | -     |
| `:coupon` | `title`, `discount_percentage`, `valid_until`, `store` | Store |

**命名例**

```ruby
FactoryBot.define do
  factory :store do
    name { "Test Store" }
  end

  factory :coupon do
    store
    title { "10% OFF" }
    discount_percentage { 10 }
    valid_until { Date.current.next_month.end_of_month }
  end
end
```

---

## 4. モデル単体テスト観点

| 対象         | 観点                             | 期待結果                       |
| ---------- | ------------------------------ | -------------------------- |
| **Store**  | `name` の必須検証                   | `Store.new(name: nil)` は無効 |
| **Coupon** | `title` 必須                     | 空欄で invalid                |
|            | `discount_percentage` 1〜100 範囲 | 0,101 は invalid            |
|            | `valid_until` 必須               | nil は invalid              |
|            | `store_id` 必須                  | nil は invalid              |
|            | `store_id, title` の一意制約        | 同一storeで同titleは invalid    |

---

## 5. API（Request Spec）観点

### 5.1 正常系

| シナリオ                            | 期待結果                                 |
| ------------------------------- | ------------------------------------ |
| クーポン一覧取得                        | 200 + JSON構造（`data[]`, `meta`）       |
| クーポン作成                          | 201 + 作成済みリソース返却                     |
| ページネーション                        | `page[size]`/`page[number]`指定でメタ情報反映 |
| `valid_until` が過去日でも登録可（論理上は許容） | スキーマに準拠していること                        |

### 5.2 異常系

| シナリオ                        | ステータス       | 内容                             |
| --------------------------- | ----------- | ------------------------------ |
| 無認証アクセス                     | 401         | JWTなし                          |
| トークン期限切れ                    | 401         | `exp`超過                        |
| テナント越境（他store_id）           | 403         | `store_id != current_store.id` |
| scope 不足 (`coupon:write`なし) | 403         | 書込不可                           |
| バリデーションエラー                  | 422         | 不正パラメータ                        |
| JSONフォーマット不正                | 400         | malformed JSON                 |
| page[size] > 100            | 400 or 自動丸め |                                |
| 内部例外                        | 500         | JSON:API形式のerrors返却            |

---

## 6. 認可テスト（Policy Spec）

| 観点                  | 期待結果                       |
| ------------------- | -------------------------- |
| 自店舗のCouponは操作可      | `authorize(coupon)` が true |
| 他店舗のCouponは操作不可     | false + Forbidden          |
| scope不足（read/write） | false                      |
| 管理者スコープ（将来拡張）       | true                       |

---

## 7. JWTテスト観点（Service Spec）

| 観点         | 期待結果                                 |
| ---------- | ------------------------------------ |
| 署名検証成功     | `JwtService.decode(token)` が sub を返す |
| 無効署名       | raise JWT::VerificationError         |
| kid 不一致    | エラー発生                                |
| exp超過      | 401返却（ApplicationControllerハンドリング）   |
| iss/aud不一致 | 拒否                                   |

---

## 8. セキュリティテスト観点

| カテゴリ           | チェック内容                                         | 結果期待             |
| -------------- | ---------------------------------------------- | ---------------- |
| **SQL越境**      | `Coupon.find` 禁止。常に `current_store.coupons` 起点 | テストで越境操作不可を確認    |
| **CORS**       | 許可オリジンのみ                                       | preflightが200    |
| **Rate Limit** | リクエスト過多で429                                    | （モックまたはシミュレーション） |
| **秘密情報露出**     | JWT秘密鍵や環境変数がレスポンスに含まれない                        | 常に非表示            |
| **例外ハンドリング**   | 想定外例外→500で汎用メッセージ                              | 内部情報非出力          |

---

## 9. 監査ログ検証観点

| イベント           | チェック内容                                                    |
| -------------- | --------------------------------------------------------- |
| クーポン作成成功       | 監査ログに `store_uid`, `jti`, `path`, `status=success` が記録される |
| 例外発生時          | status=`error` として出力される                                   |
| ログ内に個人情報が含まれない | ✅                                                         |

> ログ生成は非機能テストの一部とし、`log/`出力のモックまたはDBレコードで検証。

---

## 10. CI/CD連携

### 10.1 GitHub Actions例

```yaml
- name: Setup DB schema
  run: bundle exec ridgepole -c config/database.yml -E test -f db/Schemafile --apply
- name: Run RSpec
  run: bundle exec rspec --format documentation
```

### 10.2 成果物

* CI実行結果（RSpec summary）
* カバレッジレポート（SimpleCov）
* 失敗時スクリーンショット or APIログ（オプション）

---

## 11. 今後の拡張

| 項目         | 概要                                     |
| ---------- | -------------------------------------- |
| E2Eテスト     | Postman Collection / Newman によるAPI回帰検証 |
| 負荷テスト      | k6 / Locust による read-heavy テスト         |
| セキュリティテスト  | JWT改ざん・トークンリプレイ・CORS越境の検証              |
| パフォーマンステスト | Pagyページング・DBインデックス効果測定                 |
| モニタリング統合   | 監査ログとAPMトレースの統合（将来）                    |
