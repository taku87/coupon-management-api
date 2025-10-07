# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CouponPolicy, type: :policy do
  let(:store) { create(:store) }
  let(:other_store) { create(:store) }
  let(:coupon) { create(:coupon, store:) }
  let(:other_coupon) { create(:coupon, store: other_store) }

  describe '#index?' do
    context 'coupon:read スコープを持つ場合' do
      let(:context) { { scopes: [ 'coupon:read' ] } }
      let(:policy) { described_class.new(store, Coupon, context) }

      it 'アクセスを許可する' do
        expect(policy.index?).to be true
      end
    end

    context 'coupon:read スコープを持たない場合' do
      let(:context) { { scopes: [] } }
      let(:policy) { described_class.new(store, Coupon, context) }

      it 'アクセスを拒否する' do
        expect(policy.index?).to be false
      end
    end

    context 'coupon:write スコープのみを持つ場合' do
      let(:context) { { scopes: [ 'coupon:write' ] } }
      let(:policy) { described_class.new(store, Coupon, context) }

      it 'アクセスを拒否する' do
        expect(policy.index?).to be false
      end
    end
  end

  describe '#create?' do
    context 'coupon:write スコープを持つ場合' do
      let(:context) { { scopes: [ 'coupon:write' ] } }
      let(:policy) { described_class.new(store, Coupon, context) }

      it 'アクセスを許可する' do
        expect(policy.create?).to be true
      end
    end

    context 'coupon:write スコープを持たない場合' do
      let(:context) { { scopes: [] } }
      let(:policy) { described_class.new(store, Coupon, context) }

      it 'アクセスを拒否する' do
        expect(policy.create?).to be false
      end
    end

    context 'coupon:read スコープのみを持つ場合' do
      let(:context) { { scopes: [ 'coupon:read' ] } }
      let(:policy) { described_class.new(store, Coupon, context) }

      it 'アクセスを拒否する' do
        expect(policy.create?).to be false
      end
    end

    context 'coupon:read と coupon:write の両方を持つ場合' do
      let(:context) { { scopes: [ 'coupon:read', 'coupon:write' ] } }
      let(:policy) { described_class.new(store, Coupon, context) }

      it 'アクセスを許可する' do
        expect(policy.create?).to be true
      end
    end
  end
end
