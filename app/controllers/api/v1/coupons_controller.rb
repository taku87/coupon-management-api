# frozen_string_literal: true

module Api
  module V1
    # Coupons API Controller
    class CouponsController < ApplicationController
      def index
        policy = CouponPolicy.new(current_store, Coupon, pundit_policy_context)
        raise Pundit::NotAuthorizedError unless policy.index?

        # current_storeスコープでクーポンを取得
        coupons = current_store.coupons
        pagy, paginated_coupons = pagy(coupons, items: params[:items]&.to_i)

        render json: CouponSerializer.new(paginated_coupons).serializable_hash.merge(
          meta: pagination_meta(pagy)
        )
      end

      def create
        policy = CouponPolicy.new(current_store, Coupon, pundit_policy_context)
        raise Pundit::NotAuthorizedError unless policy.create?

        coupon = current_store.coupons.build(coupon_params)
        coupon.save!

        render json: CouponSerializer.new(coupon).serializable_hash, status: :created
      end

      private

      def coupon_params
        params.require(:coupon).permit(:title, :discount_percentage, :valid_until)
      end
    end
  end
end
