require 'rails_helper'

RSpec.describe Store, type: :model do
  describe 'associations' do
    it { should have_many(:coupons).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
  end

  describe '正常系' do
    it 'name が設定されていれば有効' do
      store = build(:store, name: 'Test Store')
      expect(store).to be_valid
    end
  end

  describe '異常系' do
    it 'name が空の場合は無効' do
      store = build(:store, name: nil)
      expect(store).to be_invalid
      expect(store.errors[:name]).to include("can't be blank")
    end
  end
end
