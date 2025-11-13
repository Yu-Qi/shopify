require "rails_helper"

RSpec.describe "API::V1::Tenants", type: :request do
  let(:user) { create(:user) }
  let!(:seller_profile) { create(:seller_profile, user: user) }
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

  describe "GET /api/v1/my-tenants" do
    it "回傳當前使用者的租戶列表" do
      create(:tenant, seller_profile: seller_profile, name: "租戶 A")

      get "/api/v1/my-tenants", headers: headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.first["name"]).to eq("租戶 A")
    end
  end

  describe "POST /api/v1/tenants" do
    it "成功建立租戶並產生預設商店" do
      payload = {
        tenant: {
          name: "新租戶",
          description: "說明文字"
        }
      }

      expect do
        post api_v1_tenants_path, params: payload.to_json, headers: headers
      end.to change(Tenant, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body.dig("tenant", "name")).to eq("新租戶")
      expect(body.dig("default_shop", "name")).to eq("新租戶 主商店")
    end

    it "缺少必要欄位時回傳錯誤" do
      post api_v1_tenants_path, params: { tenant: { name: nil } }.to_json, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["errors"]).to include("Name can't be blank")
    end
  end

  describe "GET /api/v1/tenants/:id" do
    it "回傳指定租戶" do
      tenant = create(:tenant, seller_profile: seller_profile, name: "查詢租戶")

      get api_v1_tenant_path(tenant), headers: headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["name"]).to eq("查詢租戶")
    end
  end

  describe "PATCH /api/v1/tenants/:id" do
    it "成功更新租戶資料" do
      tenant = create(:tenant, seller_profile: seller_profile, name: "舊名稱")

      patch api_v1_tenant_path(tenant), params: { tenant: { name: "新名稱" } }.to_json, headers: headers

      expect(response).to have_http_status(:ok)
      expect(tenant.reload.name).to eq("新名稱")
    end
  end

  describe "DELETE /api/v1/tenants/:id" do
    it "成功刪除租戶" do
      tenant = create(:tenant, seller_profile: seller_profile)

      delete api_v1_tenant_path(tenant), headers: headers

      expect(response).to have_http_status(:ok)
      expect(Tenant.exists?(tenant.id)).to be(false)
    end
  end
end

