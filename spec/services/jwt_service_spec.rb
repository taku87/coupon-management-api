# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JwtService, type: :service do
  let(:store_uid) { 'store_123' }
  let(:scope) { 'coupon:read coupon:write' }

  describe '.encode' do
    it 'JWTトークンを正常に生成できる' do
      token = described_class.encode(store_uid:, scope:)

      expect(token).to be_a(String)
      expect(token.split('.')).to have_attributes(size: 3)
    end

    it '指定したペイロードを含むトークンを生成する' do
      token = described_class.encode(store_uid:, scope:)
      decoded = described_class.decode(token)

      expect(decoded['sub']).to eq(store_uid)
      expect(decoded['scope']).to eq(scope)
      expect(decoded['iss']).to eq(ENV.fetch('JWT_ISSUER', 'coupon-api'))
      expect(decoded['aud']).to eq(ENV.fetch('JWT_AUDIENCE', 'coupon-api'))
    end

    it 'exp、iat、jtiを含む' do
      token = described_class.encode(store_uid:, scope:)
      decoded = described_class.decode(token)

      expect(decoded['exp']).to be_a(Integer)
      expect(decoded['iat']).to be_a(Integer)
      expect(decoded['jti']).to be_a(String)
      expect(decoded['jti']).to match(/\A[0-9a-f-]{36}\z/) # UUID形式
    end

    it 'expires_inで有効期限を設定できる' do
      expires_in = 3600
      token = described_class.encode(store_uid:, scope:, expires_in:)
      decoded = described_class.decode(token)

      expect(decoded['exp'] - decoded['iat']).to eq(expires_in)
    end

    it 'kidヘッダーを含む' do
      token = described_class.encode(store_uid:, scope:)
      header = JWT.decode(token, nil, false)[1]

      expect(header['kid']).to eq(ENV.fetch('JWT_KID', 'default-key-id'))
      expect(header['typ']).to eq('JWT')
    end
  end

  describe '.decode' do
    let(:token) { described_class.encode(store_uid:, scope:) }

    it '有効なトークンをデコードできる' do
      decoded = described_class.decode(token)

      expect(decoded).to be_a(Hash)
      expect(decoded['sub']).to eq(store_uid)
    end

    it '無効な署名のトークンで例外を発生させる' do
      invalid_token = "#{token[0..-5]}xxxx"

      expect do
        described_class.decode(invalid_token)
      end.to raise_error(JWT::DecodeError)
    end

    it '期限切れトークンで例外を発生させる' do
      # exp_leewayが60秒あるので、それを超える過去に設定
      expired_token = described_class.encode(store_uid:, scope:, expires_in: -120)

      expect do
        described_class.decode(expired_token)
      end.to raise_error(JWT::ExpiredSignature)
    end

    it '不正なissで例外を発生させる' do
      # 不正なissを含むペイロードを直接作成
      now = Time.current.to_i
      payload = {
        iss: 'invalid-issuer',
        aud: ENV.fetch('JWT_AUDIENCE', 'coupon-api'),
        sub: store_uid,
        exp: now + 900,
        iat: now,
        jti: SecureRandom.uuid,
        scope:
      }
      headers = { kid: ENV.fetch('JWT_KID', 'default-key-id'), typ: 'JWT' }
      private_key = OpenSSL::PKey::RSA.new(File.read(Rails.root.join('config/jwt_private_key.pem')))
      invalid_iss_token = JWT.encode(payload, private_key, 'RS256', headers)

      expect do
        described_class.decode(invalid_iss_token)
      end.to raise_error(JWT::InvalidIssuerError)
    end

    it '不正なaudで例外を発生させる' do
      # 不正なaudを含むペイロードを直接作成
      now = Time.current.to_i
      payload = {
        iss: ENV.fetch('JWT_ISSUER', 'coupon-api'),
        aud: 'invalid-audience',
        sub: store_uid,
        exp: now + 900,
        iat: now,
        jti: SecureRandom.uuid,
        scope:
      }
      headers = { kid: ENV.fetch('JWT_KID', 'default-key-id'), typ: 'JWT' }
      private_key = OpenSSL::PKey::RSA.new(File.read(Rails.root.join('config/jwt_private_key.pem')))
      invalid_aud_token = JWT.encode(payload, private_key, 'RS256', headers)

      expect do
        described_class.decode(invalid_aud_token)
      end.to raise_error(JWT::InvalidAudError)
    end

    it '形式不正な文字列で例外を発生させる' do
      expect do
        described_class.decode('invalid.token.string')
      end.to raise_error(JWT::DecodeError)
    end
  end
end
