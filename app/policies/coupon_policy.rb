# frozen_string_literal: true

# Couponリソースに対する認可ポリシー
class CouponPolicy < ApplicationPolicy
  # 一覧表示の権限
  def index?
    # 自店舗のクーポンのみアクセス可能
    # また、coupon:read スコープが必要
    has_scope?("coupon:read")
  end

  # 作成の権限
  def create?
    # coupon:write スコープが必要
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
