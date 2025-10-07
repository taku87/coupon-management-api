# implementation_plan.md

本ドキュメントは、クーポン管理APIの**実装順序**と**GitHub Issue一覧**を定義する。
ユーザー価値が最速で届くMVPを優先し、フェーズごとに実装を進める。

---

## フェーズ構成

| フェーズ | 目的 | 含むIssue |
|---------|------|-----------|
| **Phase 0: プロジェクト基盤** | Railsプロジェクト初期化、Docker環境構築、基本Gem導入 | #1〜#3 |
| **Phase 1: Walking Skeleton + テスト基盤** | DB→Model→最小API＋FactoryBot・Specの垂直スライス | #4〜#8, #6, #17 |
| **Phase 2: 認証・認可 + テスト** | JWT認証・Pundit認可・テナント境界制御＋対応テスト | #9, #20, #10〜#12, #19 |
| **Phase 3: 堅牢化 + テスト** | エラーハンドリング・Serializer・ページネーション・Auth API＋Request Spec | #13〜#16, #18 |
| **Phase 4: CI・仕上げ** | CI構築・Seed・ドキュメント整備 | #21〜#23 |

---

## 依存関係マップ

### Phase 0: プロジェクト基盤
```
#1 (Rails初期化)
  ↓
#2 (Docker環境)
  ↓
#3 (Gem導入)
```

### Phase 1: Walking Skeleton + テスト基盤
```
#3
  ↓
#4 (Schemafile)
  ↓
#5 (Model実装)
  ↓
#6 (FactoryBot定義) ──→ #17 (Model Spec) ※実装直後にテスト
  ↓
#7 (GET API最小実装)
  ↓
#8 (POST API最小実装)
```

### Phase 2: 認証・認可 + テスト
```
#3
  ↓
#9 (JwtService) ──→ #20 (Service Spec) ※実装直後にテスト
  ↓
#10 (ApplicationController認証)
  ↓
#11 (Pundit & Policy) ──→ #19 (Policy Spec) ※実装直後にテスト
  ↓
#12 (テナント境界強制)
```

### Phase 3: 堅牢化 + テスト
```
#12
  ↓
#13 (エラーハンドリング)
  ↓
#14 (Serializer) ───→ #15 (Pagy)
                        ↓
#9                    #16 (AuthController)
  ↓                    ↓
            ┌──────────┘
            ↓
        #18 (Request Spec) ※全API実装後にE2Eテスト
```

### Phase 4: CI・仕上げ
```
#18
  ↓
#21 (CI構築) ※全テスト揃った後
  ↓
#22 (seeds)
  ↓
#23 (README)
```

### 全体フロー（簡易版）
```
Phase 0 (#1→#2→#3)
  ↓
Phase 1 (#4→#5→#6→#17→#7→#8)
  ↓
Phase 2 (#9→#20→#10→#11→#19→#12)
  ↓
Phase 3 (#13→#14→#15→#16→#18)
  ↓
Phase 4 (#21→#22→#23)
```

---

## Issueアウトライン表

### Issue #1: Rails APIプロジェクト初期化
**概要**: Rails 8.1 API modeプロジェクトを作成し、Gitリポジトリを初期化する
**依存**: -
**ラベル**: backend, setup
**受け入れ基準（AC）**:
- [ ] `rails new coupon-management-api --api --database=postgresql` 実行完了
- [ ] `.gitignore` に `.env`, `log/`, `tmp/` を追加
- [ ] README.md に環境構築手順の雛形を記載
- [ ] git init & 初回コミット完了

---

### Issue #2: Docker環境構築（Rails + PostgreSQL）
**概要**: docker-compose.yml でRails & PostgreSQLコンテナを定義し、起動確認する
**依存**: #1
**ラベル**: infra, setup
**受け入れ基準（AC）**:
- [ ] `docker-compose.yml` にapp・db・testdb定義を追加
- [ ] `Dockerfile` にRuby 3.x + bundler構成を記述
- [ ] `docker compose up -d` で両コンテナ起動成功
- [ ] `docker compose exec app rails -v` でバージョン確認
- [ ] `.env.sample` を作成し、DATABASE_URL等の例を記載

---

### Issue #3: Gemfile整備・基本Gem導入
**概要**: ridgepole, dotenv-rails, rspec-rails, factory_bot_rails, faker を追加しbundle install
**依存**: #2
**ラベル**: backend, setup
**受け入れ基準（AC）**:
- [ ] Gemfile に以下を追加: ridgepole, dotenv-rails, pundit, pagy, jsonapi-serializer
- [ ] group :development, :test に rspec-rails, factory_bot_rails, faker 追加
- [ ] `bundle install` 成功
- [ ] `rails g rspec:install` 実行完了
- [ ] `.rspec` に `--format documentation` 追加

---

### Issue #4: Schemafile作成（Store/Coupon）
**概要**: db/Schemafile でstores・couponsテーブルを定義し、ridgepole --apply で反映
**依存**: #3
**ラベル**: backend, database
**受け入れ基準（AC）**:
- [ ] `db/Schemafile` に stores テーブル定義（id, name, timestamps）
- [ ] coupons テーブル定義（id, store_id, title, discount_percentage, valid_until, timestamps）
- [ ] FK制約・UNIQUE制約・CHECK制約（discount 1-100）を記述
- [ ] `bundle exec ridgepole -c config/database.yml -E development -f db/Schemafile --apply` 成功
- [ ] `rails dbconsole` でテーブル存在確認

---

### Issue #5: Store/Couponモデル実装
**概要**: ActiveRecordモデルを作成し、バリデーション・関連を定義する
**依存**: #4
**ラベル**: backend, model
**受け入れ基準（AC）**:
- [ ] `app/models/store.rb` に `has_many :coupons` と `validates :name, presence: true`
- [ ] `app/models/coupon.rb` に `belongs_to :store` と全バリデーション実装
- [ ] `validates :title, uniqueness: { scope: :store_id }`
- [ ] `validates :discount_percentage, inclusion: 1..100`
- [ ] rails console で Store.create / Coupon.create が動作

---

### Issue #6: FactoryBot定義（Store/Coupon）
**概要**: spec/factories に Store/Coupon のファクトリを定義
**依存**: #5
**フェーズ**: Phase 1
**ラベル**: backend, test
**受け入れ基準（AC）**:
- [ ] `spec/factories/stores.rb` で `:store` ファクトリ定義
- [ ] `spec/factories/coupons.rb` で `:coupon` ファクトリ定義（store関連含む）
- [ ] `valid_until` はデフォルトで未来日付を生成
- [ ] rails console で `FactoryBot.create(:coupon)` が成功

**→ 完了後すぐに #17 (Model Spec) を実施**

---

### Issue #7: CouponsController GET /api/v1/stores/:store_id/coupons 最小実装
**概要**: 認証なしでクーポン一覧を返す最小コントローラを実装（MVPスライス確認用）
**依存**: #5
**ラベル**: backend, api
**受け入れ基準（AC）**:
- [ ] `app/controllers/api/v1/coupons_controller.rb` 作成
- [ ] `index` アクションで `Store.find(params[:store_id]).coupons` を返す
- [ ] routes.rb に `namespace :api do namespace :v1 do resources :stores do resources :coupons, only: [:index, :create] end end end` 追加
- [ ] curl でGET成功（200）
- [ ] レスポンスはJSONで配列を返す（フォーマットは後で整形）

---

### Issue #8: CouponsController POST /api/v1/stores/:store_id/coupons 最小実装
**概要**: 認証なしでクーポンを作成できる最小実装
**依存**: #7
**ラベル**: backend, api
**受け入れ基準（AC）**:
- [ ] `create` アクションで `Store.find.coupons.create` 実装
- [ ] Strong Parameters で title, discount_percentage, valid_until のみ許可
- [ ] 成功時 201 + created resourceを返す
- [ ] バリデーションエラー時は 422
- [ ] curl でPOST成功確認

---

### Issue #9: JwtService実装（RS256署名・検証）
**概要**: RS256鍵ペアによるJWT発行・検証サービスを実装
**依存**: #3
**フェーズ**: Phase 2
**ラベル**: backend, security
**受け入れ基準（AC）**:
- [ ] `app/services/jwt_service.rb` に `encode(payload)` / `decode(token)` 実装
- [ ] RS256秘密鍵を `.env` で管理、公開鍵を `config/` に配置
- [ ] `kid`, `iss`, `aud`, `exp`, `iat`, `jti`, `sub`, `scope` をペイロードに含む
- [ ] rails console で encode/decode が正常動作
- [ ] 無効署名で JWT::VerificationError が発生

**→ 完了後すぐに #20 (Service Spec) を実施**

---

### Issue #10: ApplicationController に JWT認証機能追加
**概要**: before_action で JWT検証を行い、current_store を設定
**依存**: #9
**ラベル**: backend, security
**受け入れ基準（AC）**:
- [ ] `authenticate_request!` メソッドで Authorization Bearer トークン検証
- [ ] `current_store` を @current_store にキャッシュ
- [ ] 認証失敗時に 401 Unauthorized を返す
- [ ] CouponsController で `before_action :authenticate_request!` 追加
- [ ] curl で無トークンアクセス → 401 確認

---

### Issue #11: Pundit導入・CouponPolicy実装
**概要**: Punditを導入し、CouponPolicyでテナント境界制御を実装
**依存**: #10
**フェーズ**: Phase 2
**ラベル**: backend, security
**受け入れ基準（AC）**:
- [ ] `rails g pundit:install` 実行
- [ ] `app/policies/coupon_policy.rb` 作成
- [ ] `index?` / `create?` で `coupon.store_id == user.id` を検証
- [ ] CouponsControllerで `authorize @coupon` 呼び出し
- [ ] 他店舗クーポンへのアクセスで 403 Forbidden
- [ ] scope検証（`coupon:read` / `coupon:write`）実装

**→ 完了後すぐに #19 (Policy Spec) を実施**

---

### Issue #12: テナント境界強制（current_storeスコープ）
**概要**: すべてのクエリを `current_store.coupons` 起点に変更し、Coupon.find 禁止を徹底
**依存**: #11
**ラベル**: backend, security
**受け入れ基準（AC）**:
- [ ] CouponsController#index を `current_store.coupons` に変更
- [ ] CouponsController#create を `current_store.coupons.create` に変更
- [ ] `:store_id` パラメータと `current_store.id` の一致検証を追加
- [ ] 不一致時に 403 を返す
- [ ] コードレビューで `Coupon.find` が存在しないことを確認

---

### Issue #13: ApplicationController エラーハンドリング統一
**概要**: rescue_from で例外を JSON:API形式に変換
**依存**: #12
**ラベル**: backend, error-handling
**受け入れ基準（AC）**:
- [ ] `rescue_from ActiveRecord::RecordNotFound` → 404
- [ ] `rescue_from ActiveRecord::RecordInvalid` → 422
- [ ] `rescue_from Pundit::NotAuthorizedError` → 403
- [ ] `rescue_from JWT::VerificationError` → 401
- [ ] すべてJSON:API errors構造で返す（`errors: [{status, code, title, detail}]`）
- [ ] curl で各エラーケース確認

---

### Issue #14: CouponSerializer実装（JSON:API準拠）
**概要**: jsonapi-serializer でクーポンレスポンスを整形
**依存**: #3
**ラベル**: backend, api
**受け入れ基準（AC）**:
- [ ] `app/serializers/coupon_serializer.rb` 作成
- [ ] attributes: id, title, discount_percentage, valid_until, created_at, updated_at
- [ ] CouponsController#index/create でSerializerを使用
- [ ] レスポンスが `{data: [{id, type, attributes}]}` 形式
- [ ] curl でフォーマット確認

---

### Issue #15: Pagy導入・ページネーション実装
**概要**: GET一覧にPagyを適用し、メタ情報を返す
**依存**: #14
**ラベル**: backend, api
**受け入れ基準（AC）**:
- [ ] `config/initializers/pagy.rb` 作成（デフォルト20件、最大100件）
- [ ] CouponsController#index で `pagy(current_store.coupons)` 適用
- [ ] `page[number]` / `page[size]` パラメータ対応
- [ ] レスポンスに `meta: {page, per_page, count, pages}` を追加
- [ ] curl で `?page[size]=5&page[number]=2` 動作確認

---

### Issue #16: AuthController実装（ログインAPI）
**概要**: POST /api/v1/auth/login でJWTを発行
**依存**: #9
**フェーズ**: Phase 3
**ラベル**: backend, api
**受け入れ基準（AC）**:
- [ ] `app/controllers/api/v1/auth_controller.rb` 作成
- [ ] `login` アクションで store_uid受取 → JWT発行
- [ ] routes.rb に `post 'auth/login'` 追加
- [ ] レスポンスに `{access_token, expires_in}` を返す
- [ ] curl でログイン→トークン取得→API呼び出し成功

**→ 完了後、全APIが揃ったので #18 (Request Spec) を実施**

---

### Issue #17: Model Spec実装（Store/Coupon）
**概要**: RSpecでモデルのバリデーション・関連テストを実装
**依存**: #6
**フェーズ**: Phase 1
**ラベル**: backend, test
**受け入れ基準（AC）**:
- [ ] `spec/models/store_spec.rb` で name必須テスト
- [ ] `spec/models/coupon_spec.rb` で全バリデーションテスト
- [ ] discount_percentage範囲外（0,101）で invalid
- [ ] title一意制約（同一store内）テスト
- [ ] `bundle exec rspec spec/models` 全グリーン

**※#6完了直後に実施。モデル実装とテストをセットで完結させる**

---

### Issue #18: Request Spec実装（Coupons API）
**概要**: RSpecでクーポンAPI（GET/POST）の入出力テスト
**依存**: #16, #17
**フェーズ**: Phase 3
**ラベル**: backend, test
**受け入れ基準（AC）**:
- [ ] `spec/requests/api/v1/coupons_spec.rb` 作成
- [ ] GET一覧で200・JSON構造確認
- [ ] POST作成で201・リソース返却確認
- [ ] 無認証で401
- [ ] テナント越境で403
- [ ] バリデーションエラーで422
- [ ] `bundle exec rspec spec/requests` 全グリーン

**※#16完了後に実施。全API（Auth + Coupons）のE2Eテストを実行**

---

### Issue #19: Policy Spec実装（CouponPolicy）
**概要**: Pundit認可ロジックのRSpecテスト
**依存**: #11
**フェーズ**: Phase 2
**ラベル**: backend, test
**受け入れ基準（AC）**:
- [ ] `spec/policies/coupon_policy_spec.rb` 作成
- [ ] 自店舗クーポンで `index?` / `create?` が true
- [ ] 他店舗クーポンで false
- [ ] scope不足（`coupon:write`なし）で create? が false
- [ ] `bundle exec rspec spec/policies` 全グリーン

**※#11完了直後に実施。Policy実装とテストをセットで完結させる**

---

### Issue #20: Service Spec実装（JwtService）
**概要**: JWT発行・検証サービスのRSpecテスト
**依存**: #9
**フェーズ**: Phase 2
**ラベル**: backend, test
**受け入れ基準（AC）**:
- [ ] `spec/services/jwt_service_spec.rb` 作成
- [ ] encode/decode 正常系テスト
- [ ] 無効署名で JWT::VerificationError
- [ ] exp超過で例外発生
- [ ] `bundle exec rspec spec/services` 全グリーン

**※#9完了直後に実施。JwtService実装とテストをセットで完結させる**

---

### Issue #21: CI構築（GitHub Actions）
**概要**: GitHub ActionsでRSpec自動実行
**依存**: #18
**フェーズ**: Phase 4
**ラベル**: infra, ci
**受け入れ基準（AC）**:
- [ ] `.github/workflows/ci.yml` 作成
- [ ] PostgreSQLサービスコンテナ定義
- [ ] ridgepole --apply でテスト用DB構築
- [ ] `bundle exec rspec` 実行
- [ ] PRマージ前にCI必須チェック設定
- [ ] CI実行成功（グリーンバッジ）

**※全テストスイート（#17,#18,#19,#20）が揃った後に実施**

---

### Issue #22: db/seeds.rb 作成（初期データ）
**概要**: 開発・デモ用のサンプルデータを生成
**依存**: #5
**ラベル**: backend, data
**受け入れ基準（AC）**:
- [ ] `db/seeds.rb` に Store作成・Coupon複数作成を記述
- [ ] `rails db:seed` で正常実行
- [ ] 実行後に rails console で Store.count / Coupon.count 確認
- [ ] valid_until が過去/未来の両方を含む

---

### Issue #23: README.md・環境構築手順整備
**概要**: 環境構築・起動・テスト実行手順を最終化
**依存**: #22
**ラベル**: docs
**受け入れ基準（AC）**:
- [ ] README.md にDocker構築手順・ridgepole適用手順を記載
- [ ] .env.sample に必要な環境変数（JWT_PRIVATE_KEY等）を例示
- [ ] API仕様（エンドポイント一覧）を簡潔に記載
- [ ] ローカル動作確認手順（curl例）を追加
- [ ] 新規開発者がREADME通りに環境構築できることを確認

---

## 要確認事項

- **Issue #9**: RS256鍵ペアの生成方法・保管場所を事前確認（開発環境は.env、本番はSecrets Manager想定）
- **Issue #15**: page[size]上限100超過時の挙動（400エラー or 自動丸め）をBizと確認
- **Issue #16**: ログインAPIの認証方式（store_uid + パスワードなのか、外部IdP連携なのか）を明確化
- **Issue #21**: CI環境での環境変数注入方法（GitHub Secrets利用）を確認
