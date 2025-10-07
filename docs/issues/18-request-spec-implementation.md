# Issue #18: Request Spec実装（Coupons API）

## 背景 / 目的
RSpecでクーポンAPI（GET/POST）の入出力テストを実装し、API契約を自動検証する。
認証・認可・エラーハンドリングを含むエンドツーエンドのテストを実現する。

- **依存**: #16, #17
- **ラベル**: `backend`, `test`

---

## スコープ / 作業項目

1. `spec/requests/api/v1/coupons_spec.rb` 作成
2. GET一覧テスト実装
3. POST作成テスト実装
4. 認証・認可テスト実装
5. エラー系テスト実装
6. rspec 実行確認

---

## ゴール / 完了条件（Acceptance Criteria）

- [ ] `spec/requests/api/v1/coupons_spec.rb` 作成
- [ ] GET一覧で200・JSON構造確認
- [ ] POST作成で201・リソース返却確認
- [ ] 無認証で401
- [ ] テナント越境で403
- [ ] バリデーションエラーで422

---

## テスト観点

- **正常系**:
  - 認証ありで正常レスポンス
  - JSON:API形式のレスポンス
- **異常系**:
  - 認証なしで401
  - 他店舗アクセスで403
  - 不正パラメータで422

---

## 参照ドキュメント

- [06_testing.md](../06_testing.md) - API（Request Spec）観点（セクション5）
- [04_api.md](../04_api.md) - API仕様

---

## 実装例

```ruby
# spec/requests/api/v1/coupons_spec.rb
require 'rails_helper'

RSpec.describe 'Api::V1::Coupons', type: :request do
  let(:store) { create(:store) }
  let(:token) { JwtService.encode(sub: store.id.to_s, scope: 'coupon:read coupon:write') }
  let(:headers) { { 'Authorization' => "Bearer #{token}" } }

  describe 'GET /api/v1/stores/:store_id/coupons' do
    let!(:coupons) { create_list(:coupon, 3, store: store) }

    context '認証あり' do
      it '200を返す' do
        get "/api/v1/stores/#{store.id}/coupons", headers: headers
        expect(response).to have_http_status(:ok)
      end

      it 'JSON:API形式でレスポンスを返す' do
        get "/api/v1/stores/#{store.id}/coupons", headers: headers
        json = JSON.parse(response.body)
        expect(json).to have_key('data')
        expect(json['data']).to be_an(Array)
      end
    end

    context '認証なし' do
      it '401を返す' do
        get "/api/v1/stores/#{store.id}/coupons"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'テナント越境' do
      let(:other_store) { create(:store) }

      it '403を返す' do
        get "/api/v1/stores/#{other_store.id}/coupons", headers: headers
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'POST /api/v1/stores/:store_id/coupons' do
    let(:valid_params) do
      {
        coupon: {
          title: 'Test Coupon',
          discount_percentage: 20,
          valid_until: Date.current.next_month
        }
      }
    end

    context '認証あり・正常パラメータ' do
      it '201を返す' do
        post "/api/v1/stores/#{store.id}/coupons", params: valid_params, headers: headers
        expect(response).to have_http_status(:created)
      end

      it 'クーポンが作成される' do
        expect {
          post "/api/v1/stores/#{store.id}/coupons", params: valid_params, headers: headers
        }.to change(Coupon, :count).by(1)
      end
    end

    context 'バリデーションエラー' do
      it '422を返す' do
        post "/api/v1/stores/#{store.id}/coupons",
             params: { coupon: { title: nil } },
             headers: headers
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
```
