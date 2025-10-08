# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Pagination", type: :request do
  let(:store) { create(:store) }
  let(:token) { JwtService.encode(store_uid: store.id, scope: "coupon:read") }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  before do
    # 25件のクーポンを作成（デフォルトは20件/ページ）
    create_list(:coupon, 25, store:)
  end

  describe "GET /api/v1/coupons with pagination" do
    it "デフォルトで20件を返す" do
      get "/api/v1/coupons", headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["data"].size).to eq(20)
    end

    it "ページネーションメタデータを含む" do
      get "/api/v1/coupons", headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["meta"]).to include(
        "current_page" => 1,
        "total_pages" => 2,
        "total_count" => 25,
        "per_page" => 20
      )
    end

    it "page パラメータで2ページ目を取得できる" do
      get "/api/v1/coupons?page=2", headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["data"].size).to eq(5)
      expect(json["meta"]["current_page"]).to eq(2)
    end

    it "limit パラメータで1ページあたりの件数を変更できる" do
      get "/api/v1/coupons?limit=10", headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["data"].size).to eq(10)
      expect(json["meta"]["per_page"]).to eq(10)
      expect(json["meta"]["total_pages"]).to eq(3)
    end

    it "範囲外のページ番号は最終ページを返す" do
      get "/api/v1/coupons?page=100", headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["meta"]["current_page"]).to eq(2)
      expect(json["data"].size).to eq(5)
    end
  end
end
