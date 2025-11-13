require "rails_helper"

RSpec.describe "API::V1::Products", type: :request do
  let(:user) { create(:user) }
  let!(:seller_profile) { create(:seller_profile, user: user) }
  let!(:tenant) { create(:tenant, seller_profile: seller_profile) }
  let!(:shop) { create(:shop, tenant: tenant) }
  let(:token) { "seller-token" }
  let(:headers) do
    {
      "Authorization" => "Bearer #{token}",
      "Content-Type" => "application/json"
    }
  end

  before do
    allow(User).to receive(:from_token).and_return(user)
  end

  describe "GET /api/v1/tenants/:tenant_id/shops/:shop_id/products" do
    it "回傳商品列表" do
      create_list(:product, 2, shop: shop)

      get api_v1_tenant_shop_products_path(tenant_id: tenant.id, shop_id: shop.id), headers: headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.length).to eq(2)
    end
  end

  describe "POST /api/v1/tenants/:tenant_id/shops/:shop_id/products" do
    it "成功建立商品" do
      payload = {
        product: {
          name: "新商品",
          description: "商品描述",
          price: 120,
          stock_quantity: 5,
          status: Product::STATUS_ACTIVE
        }
      }

      expect do
        post api_v1_tenant_shop_products_path(tenant_id: tenant.id, shop_id: shop.id),
             params: payload.to_json,
             headers: headers
      end.to change(Product, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["name"]).to eq("新商品")
    end

    it "資料不符合條件時回傳錯誤" do
      post api_v1_tenant_shop_products_path(tenant_id: tenant.id, shop_id: shop.id),
           params: { product: { name: "", price: -10 } }.to_json,
           headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["errors"]).to include("Name can't be blank")
    end
  end

  describe "PATCH /api/v1/tenants/:tenant_id/shops/:shop_id/products/:id" do
    it "成功更新商品" do
      product = create(:product, shop: shop, name: "舊商品")

      patch api_v1_tenant_shop_product_path(tenant_id: tenant.id, shop_id: shop.id, id: product.id),
            params: { product: { name: "新商品" } }.to_json,
            headers: headers

      expect(response).to have_http_status(:ok)
      expect(product.reload.name).to eq("新商品")
    end
  end

  describe "DELETE /api/v1/tenants/:tenant_id/shops/:shop_id/products/:id" do
    it "成功刪除商品" do
      product = create(:product, shop: shop)

      delete api_v1_tenant_shop_product_path(tenant_id: tenant.id, shop_id: shop.id, id: product.id), headers: headers

      expect(response).to have_http_status(:ok)
      expect(Product.exists?(product.id)).to be(false)
    end
  end
end

