# Issue #9: JwtService実装（RS256署名・検証）

## 背景 / 目的
RS256鍵ペアによるJWT発行・検証サービスを実装し、ステートレス認証の基盤を構築する。
kid・iss・aud・exp・jti・scope を含むペイロードで、セキュリティ要件を満たす。

- **依存**: #3
- **ラベル**: `backend`, `security`

---

## スコープ / 作業項目

1. `app/services/jwt_service.rb` 作成
2. RS256鍵ペア生成・配置
3. `encode(payload)` 実装
4. `decode(token)` 実装
5. `.env` に秘密鍵設定
6. rails console での動作確認

---

## ゴール / 完了条件（Acceptance Criteria）

- [ ] `app/services/jwt_service.rb` に `encode(payload)` / `decode(token)` 実装
- [ ] RS256秘密鍵を `.env` で管理、公開鍵を `config/` に配置
- [ ] `kid`, `iss`, `aud`, `exp`, `iat`, `jti`, `sub`, `scope` をペイロードに含む
- [ ] rails console で encode/decode が正常動作
- [ ] 無効署名で JWT::VerificationError が発生

---

## テスト観点

- **正常系**:
  - `JwtService.encode(sub: 'store_1', scope: 'coupon:read')` が文字列トークン返却
  - `JwtService.decode(token)` が payload 返却
- **異常系**:
  - 改ざんトークンで JWT::VerificationError
  - exp 超過で JWT::ExpiredSignature

---

## 参照ドキュメント

- [05_security.md](../05_security.md) - トークン仕様（セクション2.1）
- [02_architecture.md](../02_architecture.md) - JWT認証採択理由

---

## 実装例

```ruby
# app/services/jwt_service.rb
class JwtService
  ALGORITHM = 'RS256'

  class << self
    def encode(payload)
      payload[:exp] ||= 15.minutes.from_now.to_i
      payload[:iat] ||= Time.current.to_i
      payload[:jti] ||= SecureRandom.uuid
      payload[:iss] ||= ENV.fetch('JWT_ISSUER', 'coupon-api')
      payload[:aud] ||= ENV.fetch('JWT_AUDIENCE', 'coupon-api')

      JWT.encode(payload, private_key, ALGORITHM, kid: kid)
    end

    def decode(token)
      JWT.decode(token, public_key, true, algorithm: ALGORITHM, verify_iss: true, iss: ENV['JWT_ISSUER']).first
    rescue JWT::DecodeError => e
      raise JWT::VerificationError, e.message
    end

    private

    def private_key
      OpenSSL::PKey::RSA.new(ENV['JWT_PRIVATE_KEY'])
    end

    def public_key
      OpenSSL::PKey::RSA.new(File.read(Rails.root.join('config', 'jwt_public_key.pem')))
    end

    def kid
      ENV.fetch('JWT_KID', 'default-key-id')
    end
  end
end
```

---

## 要確認事項

- RS256鍵ペア生成方法:
  ```bash
  openssl genrsa -out jwt_private_key.pem 2048
  openssl rsa -in jwt_private_key.pem -pubout -out config/jwt_public_key.pem
  ```
