# 02_architecture.md

## 目的

本ドキュメントでは、Railsアプリケーション全体のアーキテクチャ設計を示す。
利用する主要技術、ディレクトリ構成、依存関係、採択理由などを整理し、
開発・運用時の基本方針を明確にする。

---

## 1. システム構成概要

RailsをベースとしたREST API構成とする。
APIサーバはRails単体で稼働し、DBはPostgreSQLを使用する。
開発環境ではDockerを用いて各サービスをコンテナ化する。

| 構成要素     | 技術                           | 役割                 |
| -------- | ---------------------------- | ------------------ |
| アプリケーション | Ruby on Rails 8.0 (API mode) | REST API提供         |
| データベース   | PostgreSQL                   | データ永続化             |
| Webサーバ   | Puma                         | Rails標準Webサーバ      |
| 認証       | JWT（RS256, kid付）             | ステートレス認証           |
| 認可       | Pundit                       | ポリシーベース認可ロジック      |
| ページネーション | Pagy                         | 一覧APIのページ分割        |
| シリアライザ   | jsonapi-serializer           | JSON整形（JSON:API準拠） |
| スキーマ管理   | ridgepole                    | SchemafileによるDB定義  |
| テスト      | RSpec, FactoryBot, Faker     | 自動テスト              |
| 環境変数管理   | dotenv-rails（本番は外部管理）        | シークレット情報管理         |

---

### マルチテナント構成

本アプリケーションは、複数の店舗（Store）が同一アプリケーション上で自店舗データを管理する
マルチテナント型（shared schema）アーキテクチャを採用する。
（要件内に明記はないが、現在展開しているサービスやビジネス内容から鑑みて採用）

各リソース（例：Coupon）は `store_id` によりテナントスコープを保持し、
アプリケーション層では常に `current_store` にスコープを固定して操作する。
テナント境界制御・クエリガード・認可の詳細は [05_security.md](./05_security.md) を参照。

初期構成は「単一DB・共有スキーマ」とし、
将来的なスケールアウトやテナント隔離（スキーマ/DB分離）に発展できる設計を想定する。
（スケール戦略の詳細は [07_scaling.md](./07_scaling.md) に記載）

---

## 2. 採択理由

### Rails APIモード

* ルーティング・ActiveRecord・バリデーション・レスポンス管理など、Web APIに必要な基本機能が標準で揃っている
* MVC構成が明確で、小規模APIでも拡張性が確保しやすい
* JSON API専用モードにより、不要なViewやAssetを排除して軽量化できる

### PostgreSQL

* トランザクション・FK制約・インデックス設計がしやすく、RDBとしての堅牢性が高い
* 将来的にJSONBなどの拡張構造も利用可能で、スキーマ拡張性がある
* Railsとの親和性が高く、設定や移行が容易
（近年の Rails エコシステムにおいては、PostgreSQL がデフォルトの選択肢として定着している印象を持っております。ただ、現時点では両者を十分に比較できるほどの知見が自分にないため、実際にはより深い比較検討が必要だと考えております。）

### JWT認証

* セッションレス構成を実現でき、APIクライアント（SPA / モバイルアプリ）との統合が容易
* Railsサーバ側でセッションを保持しないため、スケールアウト時も管理が単純化される
* 詳細な仕様・鍵管理・セキュリティ方針は [05_security.md](./05_security.md) に記載。

### Pagy

* KaminariやWillPaginateに比べて軽量かつシンプル
* 不要なヘルパー生成がなく、API専用用途に向いている
* JSONレスポンスにメタ情報（ページ数・件数など）を簡潔に追加できる
  → ページネーション構成の実装例は [04_api.md](./04_api.md) を参照。

### jsonapi-serializer

* 高速・軽量で、ActiveModel::Serializerに比べて保守性・パフォーマンスに優れる
* JSON:API仕様に準拠し、クライアント間でのレスポンス互換性を確保しやすい
* メタ情報（ページネーション・リンク情報など）を標準形式で付与可能
* シンプルなDSLでSerializer定義ができ、RSpecでのレスポンステストも容易

#### 採択理由

ActiveModel::Serializerは柔軟性が高い一方、開発が停滞しており最新Railsとの整合性維持に課題がある。
一方、`jsonapi-serializer` は軽量・高速・仕様準拠であり、API設計の標準化と長期運用を両立できる。
→ 実装例は [04_api.md](./04_api.md) を参照。

### ridgepole

* migrationファイルではなくSchemafileによるスキーマ宣言管理を採用
* 差分をGit上でレビュー可能で、DB構造の一貫性を保ちやすい
* CI/CDや複数環境での適用を自動化しやすく、チーム開発に向いている

### RSpec + FactoryBot

* Rails標準のminitestに比べてDSLが明確で可読性が高い
* FactoryBotにより、テストデータ生成の重複を防止できる
* テストケースをGiven/When/Then形式で整理しやすく、レビュー時の理解が容易
  → CIでのridgepole適用＋RSpec実行例は [06_testing.md](./06_testing.md) を参照。

### dotenv-rails

* JWT秘密鍵やDB接続情報など、環境依存の値を安全に管理できる
* 開発環境・本番環境を切り替えやすい

開発中は `dotenv-rails` によりローカルで安全に環境値を管理する。
本番やAWS環境では、**秘匿情報は AWS Secrets Manager**、
**汎用環境変数は Terraform などのIaC** で管理する方が望ましい。（個人的な見解にはなりますが）
本課題ではデプロイ設計を範囲外とし、アプリ層管理の例として `dotenv-rails` を採用している。

---

## 3. ディレクトリ構成

```
app/
 ├── controllers/
 │    └── api/
 │         └── v1/
 │              ├── coupons_controller.rb
 │              └── auth_controller.rb
 ├── models/
 │    ├── store.rb
 │    └── coupon.rb
 ├── serializers/
 │    ├── coupon_serializer.rb
 │    └── store_serializer.rb
 ├── services/
 │    └── jwt_service.rb
 └── policies/
      └── coupon_policy.rb
```

→ 各層の最小実装は [03_database.md](./03_database.md)、[04_api.md](./04_api.md) を参照。

---

## 4. APIバージョニング方針

* すべてのエンドポイントは `/api/v1/` プレフィックスを付与する
* 将来的な機能拡張や仕様変更に備え、バージョンディレクトリ構造を採用する
* 例：`/api/v2/` 追加時に互換性を維持できるように設計
  → ルーティング設計は [04_api.md](./04_api.md) を参照。

---

## 5. 環境構築方針

### ローカル環境

```bash
$ docker compose build
$ docker compose up -d
$ docker compose exec app rails db:create
$ docker compose exec app bundle exec ridgepole -c config/database.yml -E development -f db/Schemafile --apply
$ docker compose exec app RAILS_ENV=test bundle exec ridgepole -c config/database.yml -E test -f db/Schemafile --apply
```

→ CIでの環境構築・テスト実行フローは [06_testing.md](./06_testing.md) を参照。

---

## 6. レイヤー構成と責務分離

| レイヤー       | 主な責務                             | 実装例                   |
| ---------- | -------------------------------- | --------------------- |
| Controller | 入出力処理、認証検証、例外処理                  | coupons_controller.rb |
| Model      | バリデーション、関連定義                     | coupon.rb             |
| Service    | JWT発行や外部連携などの共通処理                | jwt_service.rb        |
| Serializer | JSONレスポンスの構築（jsonapi-serializer） | coupon_serializer.rb  |
| Policy     | 認可ロジック（操作制限）                     | coupon_policy.rb      |

→ 各レイヤーのコード例は [04_api.md](./04_api.md)、[05_security.md](./05_security.md) を参照。

---

## 7. セキュリティ・認可方針

* JWTを用いたステートレス認証を採用する
* 店舗オーナーのみが自店舗のリソースにアクセス可能とする（マルチテナント境界制御）
* 詳細・実装例は [05_security.md](./05_security.md) を参照。

---

## 8. エラーハンドリング設計

* 例外は `ApplicationController` にて一元管理する
* 想定されるエラー

  * 401 Unauthorized（認証失敗）
  * 404 Not Found（リソース未存在）
  * 422 Unprocessable Entity（バリデーションエラー）

→ JSON:API準拠エラー構造とレスポンス例は [05_security.md](./05_security.md) を参照。
