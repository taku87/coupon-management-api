class Coupon < ApplicationRecord
  belongs_to :store

  validates :title, presence: true
  validates :discount_percentage, presence: true, inclusion: { in: 1..100 }
  validates :valid_until, presence: true
  validates :title, uniqueness: { scope: :store_id }
end
