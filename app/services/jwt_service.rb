# frozen_string_literal: true

require "jwt"
require "openssl"
require "securerandom"

class JwtService
  ALGORITHM = "RS256"
  CLOCK_SKEW = 60 # 秒

  class << self
    # JWTトークンを発行
    # @param store_uid [String] Store識別子（sub）
    # @param scope [String] 権限（例: "coupon:read coupon:write"）
    # @param expires_in [Integer] 有効期限（秒、デフォルト15分）
    # @return [String] JWT文字列
    def encode(store_uid:, scope: "coupon:read coupon:write", expires_in: 900)
      now = Time.current.to_i

      payload = {
        iss: jwt_issuer,
        aud: jwt_audience,
        sub: store_uid,
        exp: now + expires_in,
        iat: now,
        jti: SecureRandom.uuid,
        scope:
      }

      headers = {
        kid: jwt_kid,
        typ: "JWT"
      }

      JWT.encode(payload, private_key, ALGORITHM, headers)
    end

    # JWTトークンを検証・デコード
    # @param token [String] JWT文字列
    # @return [Hash] デコードされたペイロード
    # @raise [JWT::DecodeError] 検証失敗時
    def decode(token)
      options = {
        algorithm: ALGORITHM,
        iss: jwt_issuer,
        aud: jwt_audience,
        verify_iss: true,
        verify_aud: true,
        verify_iat: true,
        verify_exp: true,
        exp_leeway: CLOCK_SKEW,
        iat_leeway: CLOCK_SKEW
      }

      decoded = JWT.decode(token, public_key, true, options)
      decoded[0]
    end

    private

    def private_key
      @private_key ||= begin
        key_string = if ENV["JWT_PRIVATE_KEY"].present?
                       ENV["JWT_PRIVATE_KEY"]
        else
                       # 開発環境ではファイルから読み込み
                       key_path = Rails.root.join("config/jwt_private_key.pem")
                       raise "JWT private key not found" unless File.exist?(key_path)

                       File.read(key_path)
        end

        OpenSSL::PKey::RSA.new(key_string)
      end
    end

    def public_key
      @public_key ||= begin
        key_path = Rails.root.join("config/jwt_public_key.pem")
        raise "JWT public key not found" unless File.exist?(key_path)

        OpenSSL::PKey::RSA.new(File.read(key_path))
      end
    end

    def jwt_issuer
      ENV.fetch("JWT_ISSUER", "coupon-api")
    end

    def jwt_audience
      ENV.fetch("JWT_AUDIENCE", "coupon-api")
    end

    def jwt_kid
      ENV.fetch("JWT_KID", "default-key-id")
    end
  end
end
