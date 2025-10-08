# frozen_string_literal: true

class CouponPolicy < ApplicationPolicy
  def index?
    has_scope?("coupon:read")
  end

  def create?
    has_scope?("coupon:write")
  end

  private

  def has_scope?(required_scope)
    return false unless user

    # ユーザー（current_store）のscopeを取得
    # JWTペイロードからscopeを取得する必要があるため、
    # controllerで@current_scopeを設定することを想定
    scopes = context[:scopes] || []
    scopes.include?(required_scope)
  end
end
