# frozen_string_literal: true

class CouponSerializer
  include JSONAPI::Serializer

  set_type :coupon
  set_id :id

  attributes :title,
             :discount_percentage,
             :valid_until,
             :created_at,
             :updated_at
end
