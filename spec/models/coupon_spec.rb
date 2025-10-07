require 'rails_helper'

RSpec.describe Coupon, type: :model do
  describe 'associations' do
    it { should belong_to(:store) }
  end

  describe 'validations' do
    subject { build(:coupon) }

    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:discount_percentage) }
    it { should validate_presence_of(:valid_until) }

    it { should validate_inclusion_of(:discount_percentage).in_range(1..100) }

    it { should validate_uniqueness_of(:title).scoped_to(:store_id) }
  end

  describe '正常系' do
    it '全ての必須項目が設定されていれば有効' do
      coupon = build(:coupon)
      expect(coupon).to be_valid
    end

    it '有効期限が過去日でも登録可能（論理上は許容）' do
      coupon = build(:coupon, valid_until: Date.yesterday)
      expect(coupon).to be_valid
    end

    it 'discount_percentage が 1 の場合は有効' do
      coupon = build(:coupon, discount_percentage: 1)
      expect(coupon).to be_valid
    end

    it 'discount_percentage が 100 の場合は有効' do
      coupon = build(:coupon, discount_percentage: 100)
      expect(coupon).to be_valid
    end
  end

  describe '異常系' do
    it 'title が空の場合は無効' do
      coupon = build(:coupon, title: nil)
      expect(coupon).to be_invalid
      expect(coupon.errors[:title]).to include("can't be blank")
    end

    it 'discount_percentage が空の場合は無効' do
      coupon = build(:coupon, discount_percentage: nil)
      expect(coupon).to be_invalid
      expect(coupon.errors[:discount_percentage]).to include("can't be blank")
    end

    it 'valid_until が空の場合は無効' do
      coupon = build(:coupon, valid_until: nil)
      expect(coupon).to be_invalid
      expect(coupon.errors[:valid_until]).to include("can't be blank")
    end

    it 'store が空の場合は無効' do
      coupon = build(:coupon, store: nil)
      expect(coupon).to be_invalid
      expect(coupon.errors[:store]).to include("must exist")
    end

    it 'discount_percentage が 0 の場合は無効' do
      coupon = build(:coupon, discount_percentage: 0)
      expect(coupon).to be_invalid
      expect(coupon.errors[:discount_percentage]).to include("is not included in the list")
    end

    it 'discount_percentage が 101 の場合は無効' do
      coupon = build(:coupon, discount_percentage: 101)
      expect(coupon).to be_invalid
      expect(coupon.errors[:discount_percentage]).to include("is not included in the list")
    end

    it '同一store内で同じtitleは登録不可' do
      store = create(:store)
      create(:coupon, store: store, title: 'Duplicate Title')

      duplicate_coupon = build(:coupon, store: store, title: 'Duplicate Title')
      expect(duplicate_coupon).to be_invalid
      expect(duplicate_coupon.errors[:title]).to include("has already been taken")
    end

    it '異なるstore内であれば同じtitleでも登録可' do
      store1 = create(:store)
      store2 = create(:store)

      create(:coupon, store: store1, title: 'Same Title')
      coupon2 = build(:coupon, store: store2, title: 'Same Title')

      expect(coupon2).to be_valid
    end
  end
end
