require "rails_helper"

RSpec.describe "API::V1::Payments", type: :request do
  let(:buyer_user) { create(:user) }
  let!(:buyer_profile) { create(:buyer_profile, user: buyer_user) }
  let(:tenant) { create(:tenant) }
  let(:shop) { create(:shop, tenant: tenant) }
  let(:order) { create(:order, shop: shop, status: Order::STATUS_PENDING) }
  let(:token) { "buyer-token" }
  let(:headers) do
    {
      "Authorization" => "Bearer #{token}",
      "Content-Type" => "application/json"
    }
  end

  before do
    allow(User).to receive(:from_token).and_return(buyer_user)
  end

  describe "POST /api/v1/orders/:order_id/payments" do
    it "成功建立付款並更新訂單狀態" do
      payload = {
        payment: {
          amount: order.total_amount.to_s,
          payment_method: "credit_card",
          transaction_reference: "TXN-1001"
        }
      }

      expect do
        post "/api/v1/orders/#{order.id}/payments", params: payload.to_json, headers: headers
      end.to change(Payment, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["order_id"]).to eq(order.id)
      expect(order.reload.status).to eq(Order::STATUS_PROCESSING)
    end

    it "金額不符時回傳錯誤" do
      payload = {
        payment: {
          amount: (order.total_amount + 10).to_s,
          payment_method: "credit_card"
        }
      }

      post "/api/v1/orders/#{order.id}/payments", params: payload.to_json, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["errors"]).to include("付款金額與訂單金額不符")
    end

    it "訂單不存在時回傳 404" do
      post "/api/v1/orders/0/payments",
           params: { payment: { amount: "100", payment_method: "credit_card" } }.to_json,
           headers: headers

      expect(response).to have_http_status(:not_found)
      body = JSON.parse(response.body)
      expect(body["error"]).to eq("訂單不存在")
    end
  end
end

