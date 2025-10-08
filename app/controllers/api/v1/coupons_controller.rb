# frozen_string_literal: true

module Api
  module V1
    class CouponsController < ApplicationController
      before_action :verify_store_access

      def index
        policy = CouponPolicy.new(current_store, Coupon, pundit_policy_context)
        raise Pundit::NotAuthorizedError unless policy.index?

        coupons = current_store.coupons
        pagy, paginated_coupons = pagy(coupons)

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

      def verify_store_access
        raise Pundit::NotAuthorizedError if params[:store_id].to_i != current_store.id
      end

      def coupon_params
        data = params.require(:data)

        unless data[:type] == "coupon"
          raise ActionController::BadRequest, "Invalid type: expected 'coupon'"
        end

        data.require(:attributes)
            .permit(:title, :discount_percentage, :valid_until)
      end
    end
  end
end
