# CLAUDE.md

Claude Code（claude.ai/code）がこのリポジトリで作業する際の設定ルールです。
このファイルは **Claudeが開発・修正・ドキュメント整備を行う際の行動規範** を定義します。

---

## 🧭 基本ルール

### 言語設定

* **すべての応答は日本語で行う**
* コード内コメント・Docstring も日本語で記述
* エラーメッセージやAPIレスポンス例も日本語で説明
* 外部依存ライブラリのコメントや英語メッセージは必要に応じてそのまま残してよい

---

### コーディング規約

#### 一般方針

* 既存のコードスタイル・命名規則を尊重する

  * Ruby: snake_case
  * クラス名: PascalCase
* **不要なコメントを追加しない**（ただし意図が不明確な箇所は補足コメントを許可）
* RubyMine / Rubocop の自動整形規約を前提とする

#### 構文・構成

* **1メソッドの責務は単一に保つ**
* **早期リターン（guard clause）** を積極的に採用
* **private メソッド** を用いて Controller / Service の責務を整理
* N+1 クエリを防ぐため、必要に応じて `includes` / `preload` を使用

---

### ファイル管理

* **新規ファイル作成は最小限に**（既存構成に追加する）
* **docs/** 以下の `.md` はユーザー指示時のみ変更可
* ファイル追加時は `02_architecture.md` に準拠したディレクトリ構成を守る

---

## 💾 Git運用ルール

### コミットメッセージ

```
<type>: <subject>
```

* 1行・50文字以内で簡潔に記述
* 日本語で書く
* タイトル文のみ（文末句読点不要）

#### type 一覧

| type     | 意味              |
| -------- | --------------- |
| feat     | 機能追加            |
| fix      | バグ修正            |
| docs     | ドキュメント変更        |
| style    | スタイル調整（動作に影響なし） |
| refactor | 構造改善（機能変更なし）    |
| test     | テスト追加・修正        |
| chore    | ビルド/設定関連        |

#### 例

* `feat: クーポン作成APIを実装`
* `fix: バリデーションエラー時のJSONレスポンス修正`
* `docs: API仕様を更新`
* `refactor: CouponSerializerの責務を整理`

---

## 🧩 プロジェクト固有の設定

### 実行・確認コマンド

```bash
# Ridgepoleでスキーマ同期
bundle exec ridgepole -c config/database.yml -E development -f db/Schemafile --apply

# テスト実行
bundle exec rspec

# Lintチェック
bundle exec rubocop
```

### ディレクトリ構造

| ディレクトリ                    | 内容                 |
| ------------------------- | ------------------ |
| `app/controllers/api/v1/` | APIコントローラ群         |
| `app/models/`             | ActiveRecordモデル    |
| `app/serializers/`        | jsonapi-serializer |
| `app/policies/`           | Punditポリシー         |
| `app/services/`           | JWT発行など共通ロジック      |
| `spec/`                   | RSpecテスト           |
| `docs/`                   | 設計ドキュメント（参照専用）     |

---

### 参照すべきドキュメント

設計や仕様の判断は常に以下を参照：

| ファイル                      | 内容                   |
| ------------------------- | -------------------- |
| `docs/01_requirements.md` | 要件定義                 |
| `docs/02_architecture.md` | システム構成と設計方針          |
| `docs/03_database.md`     | スキーマとDB制約            |
| `docs/04_api.md`          | API仕様（リクエスト/レスポンス構造） |
| `docs/05_security.md`     | 認証・認可・セキュリティ方針       |
| `docs/06_testing.md`      | テスト方針と観点             |

---

## ⚙️ 実装ルール（重要）

1. **クエリガード厳守**

   * `Coupon.find` は禁止
   * すべて `current_store.coupons` 起点でアクセス
2. **Serializer使用**

   * `jsonapi-serializer` で統一し、JSON:API仕様準拠
3. **認可**

   * `authorize` 呼び出し必須（Punditベース）
4. **例外ハンドリング**

   * ApplicationControllerで一元管理（401 / 403 / 404 / 422 / 500）
5. **レスポンス**

   * すべてJSON形式
   * 形式は `04_api.md` に準拠
6. **テスト**

   * RSpecで自動化
   * FactoryBotを使用してテストデータ生成

---

## 🛡️ セキュリティ方針

* JWT秘密鍵や認証情報をリポジトリに含めない
* `.env` で管理するが、**本番はAWS Secrets Manager**想定
* HTTPS前提（CORS許可オリジンは限定）
* SQL Injection / mass assignment / open redirect を防止
* 監査ログにはPIIを含めない（`store_uid`, `jti`, `path`, `status`のみ）

---

## ⚡ パフォーマンス

* 不要なクエリ・ループ生成を避ける
* ActiveRecordバッチ処理 (`find_each`, `update_all`) を適切に使用
* N+1検出ツール（Bullet等）導入を想定

---

## 💥 エラーハンドリング

* rescue_fromを活用し、共通処理で例外→JSON変換を行う
* ユーザー向けメッセージは抽象化（内部エラー詳細はログにのみ出力）
* ValidationErrorなどは422を返却

---

## 🚫 行動制限（Claudeへのガード）

1. **ユーザーが明示的に依頼していない変更は禁止**
2. **ドキュメント間の整合性を自動調整しない**

   * ただし、ユーザーが「docs更新」と明示した場合のみ修正可
3. **外部通信（APIアクセス）・生成物アップロード禁止**
4. **既存コードの意図を変更しない**

---

## ✅ コードレビュー指針（Claude自身へのセルフチェック）

* 設計（02〜06.md）とコードが整合しているか
* current_storeスコープが全操作で維持されているか
* JSON構造がdocs/04_api.mdと一致しているか
* エラー処理・例外時レスポンスが標準化されているか
* 変更がスコープ外の影響を与えていないか

---

## 🧠 参考運用メモ

* このプロジェクトでは、**「設計の再現性」と「実装の正確性」**を評価対象とする
* Claudeは、docs群を常に参照し、実装方針を逸脱しないこと
* 修正時は「なぜ変更したか」をコメントに明記すること
