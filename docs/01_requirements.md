# 01_requirements.md

## 目的

本アプリケーションは、店舗が自店舗のクーポンを管理できるREST APIである。
Ruby on Rails（APIモード）を用い、認証・テスト・ページネーション・例外処理を含む実装を行う。
本ドキュメントでは、要件全体の概要と目的を整理し、
各詳細設計ドキュメント（02〜06）への導線を示す。

## 1. 全体構成

このプロジェクトの設計ドキュメントは、以下のように構成される。

| No | ファイル名                                                        | 内容                             |
| -- | ------------------------------------------------------------ | ------------------------------ |
| 00 | [00_original_requirements.md](./00_original_requirements.md) | 提示された課題原文（一次要件）                |
| 01 | 01_requirements.md                                           | 本ドキュメント。全体の要件整理と構成概要           |
| 02 | [02_architecture.md](./02_architecture.md)                   | アプリケーションアーキテクチャ、ディレクトリ構成、利用Gem |
| 03 | [03_database.md](./03_database.md)                           | モデル・ER図・マイグレーション方針             |
| 04 | [04_api.md](./04_api.md)                                     | 各APIエンドポイントの入出力仕様・設計詳細         |
| 05 | [05_security.md](./05_security.md)                           | 認証・認可・例外処理・セキュリティ対策設計          |
| 06 | [06_testing.md](./06_testing.md)                             | テスト戦略、RSpec構成、Factory設計方針      |
| 07 | [07_scaling.md](./07_scaling.md)                             | スケーリング戦略                       |


## 2. 実装ゴール（Scope）

Ruby on Railsを用いて、以下の機能を提供するREST APIを構築する。

| No | 機能          | 要件概要                            | 詳細ドキュメント                           |
| -- | ----------- | ------------------------------- | ---------------------------------- |
| 1  | 店舗のクーポン一覧取得 | 指定された店舗のクーポン一覧を返す               | [04_api.md](./04_api.md)           |
| 2  | クーポンの新規作成   | 新しいクーポンを作成し、成功時に内容を返す           | [04_api.md](./04_api.md)           |
| 3  | 認証          | 店舗オーナーのみ操作可能（JWT認証）             | [05_security.md](./05_security.md) |
| 4  | ページネーション    | 一覧APIにページネーションを実装               | [04_api.md](./04_api.md)           |
| 5  | 例外処理        | 404・422などをJSON形式で統一             | [05_security.md](./05_security.md) |
| 6  | テスト         | RSpecによるModel・Request・Policyテスト | [06_testing.md](./06_testing.md)   |


## 3. モデル設計（概要）

アプリは2つの中心モデルから構成される。

| モデル    | 役割                | 主なカラム                                                | 詳細                                 |
| ------ | ----------------- | ---------------------------------------------------- | ---------------------------------- |
| Store  | 店舗を表す             | name                                                 | [03_database.md](./03_database.md) |
| Coupon | クーポン情報を表す（店舗に属する） | title / discount_percentage / valid_until / store_id | [03_database.md](./03_database.md) |

関連

* Store has_many :coupons
* Coupon belongs_to :store

## 4. 技術構成

技術スタックやGem構成、Rails設定方針の詳細は
[02_architecture.md](./02_architecture.md) に記載。

## 5. API仕様概要

詳細なI/O仕様は [04_api.md](./04_api.md) に記載。

| 機能     | メソッド | パス                                 | 概要             |
| ------ | ---- | ---------------------------------- | -------------- |
| ログイン   | POST | `/api/v1/auth/login`               | JWT発行          |
| クーポン一覧 | GET  | `/api/v1/stores/:store_id/coupons` | クーポン一覧取得（認証必須） |
| クーポン作成 | POST | `/api/v1/stores/:store_id/coupons` | クーポン新規作成（認証必須） |

## 6. 非機能要件

* 認証：JWTによるステートレス認証
* 例外処理：全APIで統一したJSONレスポンス形式
* テスト：主要機能のRSpecカバレッジ確保
* セキュリティ：CORS対応・JWT秘密鍵の安全管理
* 拡張性：今後の管理者権限追加やStore RBAC対応を視野に入れる

## 7. 完了条件（Definition of Done）

* [ ] Store / Coupon モデルを実装
* [ ] JWT認証機能を実装（ログインAPI含む）
* [ ] GET / POST クーポンAPIを実装
* [ ] ページネーションを実装
* [ ] ApplicationControllerで例外ハンドリングを統一
* [ ] RSpecテスト（Model / Request / Policy）を作成
* [ ] JSON形式のレスポンス整形
* [ ] 全テストグリーン
