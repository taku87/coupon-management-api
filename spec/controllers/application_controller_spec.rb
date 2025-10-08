# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationController, type: :controller do
  # ApplicationControllerは抽象クラスのため、RSpecの`controller do`ブロックで
  # 匿名コントローラを動的に生成してテストする
  # 各アクションは特定の例外を発生させるトリガーとして機能
  controller do
    def index
      head :ok
    end

    def show
      raise ActiveRecord::RecordNotFound, "Coupon not found"
    end

    def create
      coupon = Coupon.new
      coupon.save! # バリデーションエラーを発生させる
    end

    def update
      authorize Coupon, :update?
      head :ok
    end
  end

  let(:store) { create(:store) }
  let(:token) { JwtService.encode(store_uid: store.id, scope: "coupon:read") }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  before do
    routes.draw do
      get "index" => "anonymous#index"
      get "show" => "anonymous#show"
      post "create" => "anonymous#create"
      patch "update" => "anonymous#update"
    end
  end

  describe "エラーハンドリング" do
    context "401 Unauthorized" do
      it "トークンがない場合" do
        get :index

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json["errors"]).to be_an(Array)
        expect(json["errors"].first["status"]).to eq("401")
        expect(json["errors"].first["code"]).to eq("unauthorized")
      end

      it "無効なトークンの場合" do
        request.headers["Authorization"] = "Bearer invalid_token"
        get :index

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json["errors"].first["status"]).to eq("401")
        expect(json["errors"].first["code"]).to eq("invalid_token")
      end

      it "期限切れトークンの場合" do
        expired_token = JwtService.encode(store_uid: store.id, scope: "coupon:read", expires_in: -120)
        request.headers["Authorization"] = "Bearer #{expired_token}"
        get :index

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json["errors"].first["status"]).to eq("401")
      end
    end

    context "403 Forbidden" do
      it "Pundit認可エラーの場合" do
        write_token = JwtService.encode(store_uid: store.id, scope: "coupon:write")
        request.headers["Authorization"] = "Bearer #{write_token}"

        patch :update

        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json["errors"].first["status"]).to eq("403")
        expect(json["errors"].first["code"]).to eq("forbidden")
      end
    end

    context "404 Not Found" do
      it "RecordNotFoundの場合" do
        request.headers["Authorization"] = "Bearer #{token}"
        get :show

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json["errors"].first["status"]).to eq("404")
        expect(json["errors"].first["code"]).to eq("not_found")
        expect(json["errors"].first["detail"]).to include("Coupon not found")
      end
    end

    context "422 Unprocessable Entity" do
      it "RecordInvalidの場合" do
        request.headers["Authorization"] = "Bearer #{token}"
        post :create

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["errors"].first["status"]).to eq("422")
        expect(json["errors"].first["code"]).to eq("invalid_record")
        expect(json["errors"].first["detail"]).to be_present
      end
    end
  end

  describe "認証成功" do
    it "正しいトークンでアクセスできる" do
      request.headers["Authorization"] = "Bearer #{token}"
      get :index

      expect(response).to have_http_status(:ok)
    end

    it "current_storeが設定される" do
      request.headers["Authorization"] = "Bearer #{token}"
      get :index

      expect(controller.send(:current_store)).to eq(store)
    end
  end
end
