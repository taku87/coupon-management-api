# frozen_string_literal: true

# Couponリソースのシリアライザ（JSON:API準拠）
class CouponSerializer
  include JSONAPI::Serializer

  set_type :coupon
  set_id :id

  attributes :title,
             :discount_percentage,
             :valid_until,
             :created_at,
             :updated_at

  # Store情報を含める
  belongs_to :store
end
