class ApplicationController < ActionController::API
  include Pundit::Authorization
  include Pagy::Backend

  # カスタム例外クラス
  class AuthenticationError < StandardError; end

  before_action :authenticate_request!

  # エラーハンドリング（JSON:API形式）
  rescue_from ActiveRecord::RecordNotFound, with: :handle_record_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :handle_record_invalid
  rescue_from Pundit::NotAuthorizedError, with: :handle_forbidden
  rescue_from AuthenticationError, with: :handle_authentication_error
  rescue_from JWT::DecodeError, JWT::ExpiredSignature, JWT::VerificationError, with: :handle_jwt_error
  rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing

  private

  def authenticate_request!
    token = extract_token_from_header
    raise AuthenticationError, "トークンが見つかりません" unless token

    decoded = JwtService.decode(token)
    @current_store = Store.find_by!(id: decoded["sub"])
    raise AuthenticationError, "有効なストアが見つかりません" unless @current_store

    @current_scopes = decoded["scope"]&.split(" ") || []
  end

  def current_store
    @current_store
  end

  def pundit_user
    @current_store
  end

  def pundit_policy_context
    { scopes: @current_scopes }
  end

  def extract_token_from_header
    header = request.headers["Authorization"]
    return nil unless header&.start_with?("Bearer ")

    header.split(" ").last
  end

  # 404 Not Found
  def handle_record_not_found(exception)
    render json: {
      errors: [ {
        status: "404",
        code: "not_found",
        title: "リソースが見つかりません",
        detail: exception.message
      } ]
    }, status: :not_found
  end

  # 422 Unprocessable Entity
  def handle_record_invalid(exception)
    render json: {
      errors: [ {
        status: "422",
        code: "invalid_record",
        title: "バリデーションエラー",
        detail: exception.record.errors.full_messages.join(", ")
      } ]
    }, status: :unprocessable_entity
  end

  # 403 Forbidden
  def handle_forbidden(_exception)
    render json: {
      errors: [ {
        status: "403",
        code: "forbidden",
        title: "アクセス権限がありません",
        detail: "このリソースへのアクセスは許可されていません"
      } ]
    }, status: :forbidden
  end

  # 401 Unauthorized (AuthenticationError)
  def handle_authentication_error(exception)
    render json: {
      errors: [ {
        status: "401",
        code: "unauthorized",
        title: "認証に失敗しました",
        detail: exception.message
      } ]
    }, status: :unauthorized
  end

  # 401 Unauthorized (JWT errors)
  def handle_jwt_error(exception)
    render json: {
      errors: [ {
        status: "401",
        code: "invalid_token",
        title: "トークンが無効です",
        detail: exception.message
      } ]
    }, status: :unauthorized
  end

  # 400 Bad Request (Parameter Missing)
  def handle_parameter_missing(exception)
    render json: {
      errors: [ {
        status: "400",
        code: "bad_request",
        title: "パラメータが不足しています",
        detail: exception.message
      } ]
    }, status: :bad_request
  end

  # ページネーションメタデータを生成
  def pagination_meta(pagy)
    {
      current_page: pagy.page,
      total_pages: pagy.pages,
      total_count: pagy.count,
      per_page: pagy.limit
    }
  end
end
