# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Auth API", type: :request do
  let(:store) { create(:store) }

  describe "POST /api/v1/auth/login" do
    context "有効なstore_uidの場合" do
      let(:valid_params) do
        {
          auth: {
            store_uid: store.id,
            scope: "coupon:read coupon:write"
          }
        }
      end

      it "JWTトークンを返す" do
        post "/api/v1/auth/login", params: valid_params, as: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json).to have_key("access_token")
        expect(json).to have_key("token_type")
        expect(json).to have_key("expires_in")
        expect(json).to have_key("scope")

        expect(json["token_type"]).to eq("Bearer")
        expect(json["expires_in"]).to eq(900)
        expect(json["scope"]).to eq("coupon:read coupon:write")
      end

      it "発行されたトークンが有効" do
        post "/api/v1/auth/login", params: valid_params, as: :json

        json = JSON.parse(response.body)
        token = json["access_token"]

        decoded = JwtService.decode(token)
        expect(decoded["sub"]).to eq(store.id)
        expect(decoded["scope"]).to eq("coupon:read coupon:write")
      end
    end

    context "scopeパラメータを省略した場合" do
      let(:params_without_scope) do
        {
          auth: {
            store_uid: store.id
          }
        }
      end

      it "デフォルトのscopeでトークンを発行する" do
        post "/api/v1/auth/login", params: params_without_scope, as: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json["scope"]).to eq("coupon:read coupon:write")
      end
    end

    context "存在しないstore_uidの場合" do
      let(:invalid_params) do
        {
          auth: {
            store_uid: 99999,
            scope: "coupon:read"
          }
        }
      end

      it "404エラーを返す" do
        post "/api/v1/auth/login", params: invalid_params, as: :json

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)

        expect(json["errors"]).to be_an(Array)
        expect(json["errors"].first["status"]).to eq("404")
      end
    end

    context "パラメータが不正な場合" do
      it "400エラーを返す" do
        post "/api/v1/auth/login", params: {}, as: :json

        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
