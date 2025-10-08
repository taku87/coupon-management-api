# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API::V1::Coupons", type: :request do
  let(:store) { create(:store) }
  let(:other_store) { create(:store) }
  let(:token) { JwtService.encode(store_uid: store.id, scope: "coupon:read coupon:write") }
  let(:read_only_token) { JwtService.encode(store_uid: store.id, scope: "coupon:read") }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  describe "GET /api/v1/coupons" do
    before do
      create_list(:coupon, 3, store:)
      create_list(:coupon, 2, store: other_store)
    end

    context "認証ありでcoupon:readスコープを持つ場合" do
      it "自店舗のクーポン一覧を返す" do
        get "/api/v1/coupons", headers: { "Authorization" => "Bearer #{read_only_token}" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json["data"]).to be_an(Array)
        expect(json["data"].size).to eq(3)
        expect(json["data"].first).to have_key("id")
        expect(json["data"].first).to have_key("type")
        expect(json["data"].first).to have_key("attributes")
        expect(json["data"].first["type"]).to eq("coupon")
      end

      it "他店舗のクーポンは含まれない" do
        get "/api/v1/coupons", headers: { "Authorization" => "Bearer #{read_only_token}" }

        json = JSON.parse(response.body)
        coupon_ids = json["data"].map { |c| c["id"].to_i }
        other_coupon_ids = other_store.coupons.pluck(:id)

        expect(coupon_ids & other_coupon_ids).to be_empty
      end

      it "ページネーションメタデータを含む" do
        get "/api/v1/coupons", headers: { "Authorization" => "Bearer #{read_only_token}" }

        json = JSON.parse(response.body)

        expect(json["meta"]).to include(
          "current_page" => 1,
          "total_count" => 3,
          "per_page" => 20
        )
      end
    end

    context "認証なしの場合" do
      it "401エラーを返す" do
        get "/api/v1/coupons"

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)

        expect(json["errors"]).to be_an(Array)
        expect(json["errors"].first["status"]).to eq("401")
      end
    end

    context "coupon:readスコープを持たない場合" do
      let(:write_only_token) { JwtService.encode(store_uid: store.id, scope: "coupon:write") }

      it "403エラーを返す" do
        get "/api/v1/coupons", headers: { "Authorization" => "Bearer #{write_only_token}" }

        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)

        expect(json["errors"]).to be_an(Array)
        expect(json["errors"].first["status"]).to eq("403")
      end
    end
  end

  describe "POST /api/v1/coupons" do
    let(:valid_params) do
      {
        coupon: {
          title: "新春セール",
          discount_percentage: 20,
          valid_until: 30.days.from_now.to_date
        }
      }
    end

    context "認証ありでcoupon:writeスコープを持つ場合" do
      it "クーポンを作成し201を返す" do
        expect do
          post "/api/v1/coupons", params: valid_params, headers: headers, as: :json
        end.to change(store.coupons, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)

        expect(json["data"]).to have_key("id")
        expect(json["data"]["type"]).to eq("coupon")
        expect(json["data"]["attributes"]["title"]).to eq("新春セール")
        expect(json["data"]["attributes"]["discount_percentage"]).to eq(20)
      end

      it "作成したクーポンはcurrent_storeに紐づく" do
        post "/api/v1/coupons", params: valid_params, headers: headers, as: :json

        json = JSON.parse(response.body)
        coupon = Coupon.find(json["data"]["id"])

        expect(coupon.store_id).to eq(store.id)
      end
    end

    context "バリデーションエラーの場合" do
      let(:invalid_params) do
        {
          coupon: {
            title: "",
            discount_percentage: 150,
            valid_until: nil
          }
        }
      end

      it "422エラーを返す" do
        post "/api/v1/coupons", params: invalid_params, headers: headers, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)

        expect(json["errors"]).to be_an(Array)
        expect(json["errors"].first["status"]).to eq("422")
      end
    end

    context "認証なしの場合" do
      it "401エラーを返す" do
        post "/api/v1/coupons", params: valid_params, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "coupon:writeスコープを持たない場合" do
      it "403エラーを返す" do
        post "/api/v1/coupons", params: valid_params, headers: { "Authorization" => "Bearer #{read_only_token}" }, as: :json

        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)

        expect(json["errors"]).to be_an(Array)
        expect(json["errors"].first["status"]).to eq("403")
      end
    end
  end
end
