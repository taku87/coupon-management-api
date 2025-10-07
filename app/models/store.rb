class Store < ApplicationRecord
  has_many :coupons, dependent: :destroy

  validates :name, presence: true
end
