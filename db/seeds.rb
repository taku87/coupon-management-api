# frozen_string_literal: true

puts "Seeding data..."

# 既存データをクリア（開発環境のみ）
if Rails.env.development?
  puts "Cleaning existing data..."
  Coupon.destroy_all
  Store.destroy_all
end

# Store作成
store1 = Store.create!(name: "サンプルストア1")
store2 = Store.create!(name: "サンプルストア2")
store3 = Store.create!(name: "テストストア")

puts "Created #{Store.count} stores"

# Store1のクーポン（有効期限が多様）
store1.coupons.create!([
  {
    title: "10% OFFクーポン",
    discount_percentage: 10,
    valid_until: Date.current.end_of_month
  },
  {
    title: "夏の大セール",
    discount_percentage: 20,
    valid_until: Date.current.next_month.end_of_month
  },
  {
    title: "期限切れクーポン（過去）",
    discount_percentage: 15,
    valid_until: Date.current.prev_month.end_of_month
  },
  {
    title: "新規会員限定",
    discount_percentage: 25,
    valid_until: Date.current + 14.days
  },
  {
    title: "GWキャンペーン",
    discount_percentage: 30,
    valid_until: Date.current + 60.days
  }
])

# Store2のクーポン
store2.coupons.create!([
  {
    title: "ウィンターキャンペーン",
    discount_percentage: 30,
    valid_until: Date.current + 90.days
  },
  {
    title: "早朝割引",
    discount_percentage: 5,
    valid_until: Date.current + 7.days
  },
  {
    title: "平日限定クーポン",
    discount_percentage: 12,
    valid_until: Date.current + 30.days
  },
  {
    title: "昨年のクーポン（期限切れ）",
    discount_percentage: 20,
    valid_until: Date.current - 365.days
  }
])

# Store3のクーポン（少量）
store3.coupons.create!([
  {
    title: "初回限定50%OFF",
    discount_percentage: 50,
    valid_until: Date.current + 180.days
  },
  {
    title: "友達紹介キャンペーン",
    discount_percentage: 15,
    valid_until: Date.current + 45.days
  }
])

puts "Created #{Coupon.count} coupons"
puts ""
puts "=== Seed Data Summary ==="
puts "Stores:"
Store.all.each do |store|
  puts "  - #{store.name} (ID: #{store.id}) - #{store.coupons.count} coupons"
end
puts ""
puts "Coupons by validity:"
puts "  - Valid: #{Coupon.where('valid_until >= ?', Date.current).count}"
puts "  - Expired: #{Coupon.where('valid_until < ?', Date.current).count}"
puts ""
puts "Seeding completed!"
