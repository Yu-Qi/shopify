require "rails_helper"

RSpec.describe "API::V1::Orders", type: :request do
  let(:user) { create(:user) }
  let!(:seller_profile) { create(:seller_profile, user: user) }
  let!(:tenant) { create(:tenant, seller_profile: seller_profile) }
  let!(:shop) { create(:shop, tenant: tenant, status: Shop::STATUS_ACTIVE) }
  let!(:product) { create(:product, shop: shop, stock_quantity: 10, price: BigDecimal("99.99")) }
  let(:token) { "test-token" }
  let(:headers) do
    {
      "Authorization" => "Bearer #{token}",
      "Content-Type" => "application/json"
    }
  end
  let(:order_params) do
    {
      order: {
        customer_name: "王小明",
        customer_email: "customer@example.com",
        shipping_address: "台北市信義區市府路 45 號",
        order_items: [
          { product_id: product.id, quantity: 2 }
        ]
      }
    }
  end

  before do
    allow(User).to receive(:from_token).and_return(user)
  end

  describe "POST /api/v1/tenants/:tenant_id/shops/:shop_id/orders" do
    it "creates a new order and responds with order details" do
      expect do
        post api_v1_tenant_shop_orders_path(tenant_id: tenant.id, shop_id: shop.id),
             params: order_params.to_json,
             headers: headers
      end.to change(Order, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["customer_name"]).to eq("王小明")
      expect(body["order_items"].first["quantity"]).to eq(2)
      expect(product.reload.stock_quantity).to eq(8)
    end

    it "returns validation errors when payload invalid" do
      invalid_params = order_params.deep_merge(order: { order_items: [{ product_id: product.id, quantity: 0 }] })

      post api_v1_tenant_shop_orders_path(tenant_id: tenant.id, shop_id: shop.id),
           params: invalid_params.to_json,
           headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["errors"]).to include(a_string_including("數量必須大於 0"))
    end
  end

  describe "PATCH /api/v1/tenants/:tenant_id/shops/:shop_id/orders/:id/cancel" do
    it "cancels an existing order and restores inventory" do
      order = create(:order, shop: shop, status: Order::STATUS_PENDING)
      item = order.order_items.first
      original_stock = item.product.stock_quantity

      patch cancel_api_v1_tenant_shop_order_path(tenant_id: tenant.id, shop_id: shop.id, id: order.id),
            headers: headers

      expect(response).to have_http_status(:ok)
      expect(order.reload.status).to eq(Order::STATUS_CANCELLED)
      expect(item.product.reload.stock_quantity).to eq(original_stock + item.quantity)
    end
  end
end

