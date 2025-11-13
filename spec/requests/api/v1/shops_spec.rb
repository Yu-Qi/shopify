require "rails_helper"

RSpec.describe "API::V1::Shops", type: :request do
  let(:user) { create(:user) }
  let!(:seller_profile) { create(:seller_profile, user: user) }
  let!(:tenant) { create(:tenant, seller_profile: seller_profile) }
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

  describe "GET /api/v1/shops" do
    it "回傳商店列表" do
      create_list(:shop, 2, tenant: tenant)

      get api_v1_shops_path, headers: headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.length).to eq(tenant.shops.count)
    end
  end

  describe "POST /api/v1/shops" do
    it "成功建立商店" do
      payload = {
        shop: {
          name: "新商店",
          description: "商店描述",
          status: Shop::STATUS_ACTIVE
        }
      }

      expect do
        post api_v1_shops_path, params: payload.to_json, headers: headers
      end.to change(Shop, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["name"]).to eq("新商店")
    end

    it "當參數無效時回傳錯誤" do
      post api_v1_shops_path,
           params: { shop: { name: "" } }.to_json,
           headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["errors"]).to include("Name can't be blank")
    end
  end

  describe "PATCH /api/v1/shops/:id" do
    it "成功更新商店資訊" do
      shop = create(:shop, tenant: tenant, name: "舊名稱")

      patch api_v1_shop_path(id: shop.id),
            params: { shop: { name: "新名稱" } }.to_json,
            headers: headers

      expect(response).to have_http_status(:ok)
      expect(shop.reload.name).to eq("新名稱")
    end
  end

  describe "DELETE /api/v1/shops/:id" do
    it "成功刪除商店" do
      shop = create(:shop, tenant: tenant)

      delete api_v1_shop_path(id: shop.id), headers: headers

      expect(response).to have_http_status(:ok)
      expect(Shop.exists?(shop.id)).to be(false)
    end
  end
end

