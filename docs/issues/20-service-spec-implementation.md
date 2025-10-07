# Issue #20: Service Spec実装（JwtService）

## 背景 / 目的
JWT発行・検証サービスのRSpecテストを実装し、認証基盤の正確性を自動検証する。
トークン署名・検証ロジックの正確性を担保し、セキュリティリグレッションを防止する。

- **依存**: #9
- **ラベル**: `backend`, `test`

---

## スコープ / 作業項目

1. `spec/services/jwt_service_spec.rb` 作成
2. encode/decode 正常系テスト実装
3. 異常系テスト実装
4. rspec 実行確認

---

## ゴール / 完了条件（Acceptance Criteria）

- [ ] `spec/services/jwt_service_spec.rb` 作成
- [ ] encode/decode 正常系テスト
- [ ] 無効署名で JWT::VerificationError
- [ ] exp超過で例外発生
- [ ] `bundle exec rspec spec/services` 全グリーン

---

## テスト観点

- **正常系**:
  - encode が文字列トークン返却
  - decode が payload 返却
  - 必須クレーム（iss, aud, exp等）が含まれる
- **異常系**:
  - 改ざんトークンで例外
  - exp 超過で例外

---

## 参照ドキュメント

- [06_testing.md](../06_testing.md) - JWTテスト観点（セクション7）
- [05_security.md](../05_security.md) - JWT仕様

---

## 実装例

```ruby
# spec/services/jwt_service_spec.rb
require 'rails_helper'

RSpec.describe JwtService do
  describe '.encode' do
    it 'JWT文字列を返す' do
      payload = { sub: 'store_1', scope: 'coupon:read' }
      token = described_class.encode(payload)
      expect(token).to be_a(String)
    end

    it '必須クレームを含む' do
      payload = { sub: 'store_1' }
      token = described_class.encode(payload)
      decoded = described_class.decode(token)

      expect(decoded['sub']).to eq('store_1')
      expect(decoded['exp']).to be_present
      expect(decoded['iat']).to be_present
      expect(decoded['jti']).to be_present
      expect(decoded['iss']).to be_present
      expect(decoded['aud']).to be_present
    end
  end

  describe '.decode' do
    it '有効なトークンをデコードできる' do
      payload = { sub: 'store_1', scope: 'coupon:read' }
      token = described_class.encode(payload)
      decoded = described_class.decode(token)

      expect(decoded['sub']).to eq('store_1')
      expect(decoded['scope']).to eq('coupon:read')
    end

    it '無効な署名でエラーを発生させる' do
      invalid_token = 'invalid.jwt.token'
      expect {
        described_class.decode(invalid_token)
      }.to raise_error(JWT::VerificationError)
    end

    it 'exp超過でエラーを発生させる' do
      payload = { sub: 'store_1', exp: 1.hour.ago.to_i }
      token = JWT.encode(payload, OpenSSL::PKey::RSA.new(ENV['JWT_PRIVATE_KEY']), 'RS256')

      expect {
        described_class.decode(token)
      }.to raise_error(JWT::ExpiredSignature)
    end
  end
end
```
