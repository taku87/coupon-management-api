# Issue #19: Policy Spec実装（CouponPolicy）

## 背景 / 目的
Pundit認可ロジックのRSpecテストを実装し、テナント境界制御を自動検証する。
認可ルールの正確性を担保し、セキュリティリグレッションを防止する。

- **依存**: #11
- **ラベル**: `backend`, `test`

---

## スコープ / 作業項目

1. `spec/policies/coupon_policy_spec.rb` 作成
2. index? / create? テスト実装
3. scope検証テスト実装
4. rspec 実行確認

---

## ゴール / 完了条件（Acceptance Criteria）

- [ ] `spec/policies/coupon_policy_spec.rb` 作成
- [ ] 自店舗クーポンで `index?` / `create?` が true
- [ ] 他店舗クーポンで false
- [ ] scope不足（`coupon:write`なし）で create? が false
- [ ] `bundle exec rspec spec/policies` 全グリーン

---

## テスト観点

- **認可成功**:
  - 自店舗 + 適切なscope で true
- **認可失敗**:
  - 他店舗で false
  - scope 不足で false

---

## 参照ドキュメント

- [06_testing.md](../06_testing.md) - 認可テスト（セクション6）
- [05_security.md](../05_security.md) - Policy仕様

---

## 実装例

```ruby
# spec/policies/coupon_policy_spec.rb
require 'rails_helper'

RSpec.describe CouponPolicy, type: :policy do
  subject { described_class }

  let(:store) { create(:store) }
  let(:other_store) { create(:store) }
  let(:coupon) { create(:coupon, store: store) }
  let(:other_coupon) { create(:coupon, store: other_store) }

  describe 'index?' do
    context 'coupon:read scope あり' do
      let(:user) { double('User', id: store.id, scopes: ['coupon:read']) }

      it 'true を返す' do
        expect(subject.new(user, coupon).index?).to be true
      end
    end

    context 'scope なし' do
      let(:user) { double('User', id: store.id, scopes: []) }

      it 'false を返す' do
        expect(subject.new(user, coupon).index?).to be false
      end
    end
  end

  describe 'create?' do
    context '自店舗 + coupon:write scope あり' do
      let(:user) { double('User', id: store.id, scopes: ['coupon:write']) }

      it 'true を返す' do
        expect(subject.new(user, coupon).create?).to be true
      end
    end

    context '他店舗' do
      let(:user) { double('User', id: store.id, scopes: ['coupon:write']) }

      it 'false を返す' do
        expect(subject.new(user, other_coupon).create?).to be false
      end
    end

    context 'scope 不足' do
      let(:user) { double('User', id: store.id, scopes: ['coupon:read']) }

      it 'false を返す' do
        expect(subject.new(user, coupon).create?).to be false
      end
    end
  end
end
```
