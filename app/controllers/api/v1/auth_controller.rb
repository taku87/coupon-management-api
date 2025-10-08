# frozen_string_literal: true

module Api
  module V1
    # 認証API Controller
    class AuthController < ApplicationController
      skip_before_action :authenticate_request!, only: [ :login ]

      def login
        store = Store.find_by!(id: login_params[:store_uid])

        # JWTトークン発行
        token = JwtService.encode(
          store_uid: store.id,
          scope: login_params[:scope] || "coupon:read coupon:write",
          expires_in: 900 # 15分
        )

        render json: {
          access_token: token,
          token_type: "Bearer",
          expires_in: 900,
          scope: login_params[:scope] || "coupon:read coupon:write"
        }, status: :ok
      end

      private

      def login_params
        params.require(:auth).permit(:store_uid, :scope)
      end
    end
  end
end
