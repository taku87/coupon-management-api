FactoryBot.define do
  factory :coupon do
    association :store
    title { Faker::Commerce.promotion_code }
    discount_percentage { Faker::Number.between(from: 1, to: 100) }
    valid_until { Faker::Date.between(from: Date.current, to: 1.year.from_now) }
  end
end
