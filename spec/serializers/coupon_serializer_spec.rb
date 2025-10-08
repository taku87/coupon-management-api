# frozen_string_literal: true

require "rails_helper"

RSpec.describe CouponSerializer, type: :serializer do
  let(:store) { create(:store) }
  let(:coupon) { create(:coupon, store:) }
  let(:serializer) { described_class.new(coupon) }
  let(:serialized_json) { serializer.serializable_hash }

  describe "シリアライズ" do
    it "JSON:API形式でシリアライズできる" do
      expect(serialized_json).to have_key(:data)
      expect(serialized_json[:data]).to have_key(:id)
      expect(serialized_json[:data]).to have_key(:type)
      expect(serialized_json[:data]).to have_key(:attributes)
    end

    it "typeがcouponである" do
      expect(serialized_json[:data][:type]).to eq(:coupon)
    end

    it "idが文字列として含まれる" do
      expect(serialized_json[:data][:id]).to eq(coupon.id.to_s)
    end

    it "必須属性が含まれる" do
      attributes = serialized_json[:data][:attributes]

      expect(attributes).to have_key(:title)
      expect(attributes).to have_key(:discount_percentage)
      expect(attributes).to have_key(:valid_until)
      expect(attributes).to have_key(:created_at)
      expect(attributes).to have_key(:updated_at)
    end

    it "属性値が正しい" do
      attributes = serialized_json[:data][:attributes]

      expect(attributes[:title]).to eq(coupon.title)
      expect(attributes[:discount_percentage]).to eq(coupon.discount_percentage)
      expect(attributes[:valid_until]).to eq(coupon.valid_until)
    end
  end

  describe "リレーションシップ" do
    it "storeリレーションを持つ" do
      expect(serialized_json[:data]).to have_key(:relationships)
      expect(serialized_json[:data][:relationships]).to have_key(:store)
    end

    it "store_idが正しい" do
      store_data = serialized_json[:data][:relationships][:store][:data]

      expect(store_data[:id]).to eq(store.id.to_s)
      expect(store_data[:type]).to eq(:store)
    end
  end

  describe "複数リソース" do
    let(:coupons) { create_list(:coupon, 3, store:) }
    let(:serializer) { described_class.new(coupons) }

    it "複数のクーポンをシリアライズできる" do
      expect(serialized_json[:data]).to be_an(Array)
      expect(serialized_json[:data].size).to eq(3)
      expect(serialized_json[:data].first[:type]).to eq(:coupon)
    end
  end
end
