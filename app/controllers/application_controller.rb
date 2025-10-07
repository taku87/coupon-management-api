class ApplicationController < ActionController::API
  include Pundit::Authorization

  before_action :authenticate_request!

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def authenticate_request!
    token = extract_token_from_header
    raise AuthenticationError, "トークンが見つかりません" unless token

    decoded = JwtService.decode(token)
    @current_store = Store.find_by!(id: decoded["sub"])
    @current_scopes = decoded["scope"]&.split(" ") || []
  rescue JWT::DecodeError, JWT::ExpiredSignature, JWT::VerificationError => e
    raise AuthenticationError, "認証に失敗しました: #{e.message}"
  rescue ActiveRecord::RecordNotFound
    raise AuthenticationError, "有効なストアが見つかりません"
  end

  def current_store
    @current_store
  end

  def pundit_user
    @current_store
  end

  def pundit_context
    { scopes: @current_scopes }
  end

  def extract_token_from_header
    header = request.headers["Authorization"]
    return nil unless header&.start_with?("Bearer ")

    header.split(" ").last
  end

  def user_not_authorized
    render json: {
      errors: [ {
        status: "403",
        code: "forbidden",
        title: "アクセス権限がありません",
        detail: "このリソースへのアクセスは許可されていません"
      } ]
    }, status: :forbidden
  end

  class AuthenticationError < StandardError; end
end
