require "rails_helper"

RSpec.describe "API::V1::SellerProfiles", type: :request do
  let(:user) { create(:user) }
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

  describe "GET /api/v1/seller_profile" do
    context "當已有店家資料" do
      let!(:seller_profile) { create(:seller_profile, user: user, display_name: "測試商家") }

      it "回傳店家資訊" do
        get api_v1_seller_profile_path, headers: headers

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["display_name"]).to eq("測試商家")
      end
    end

    context "當尚未建立店家資料" do
      it "回傳 404" do
        get api_v1_seller_profile_path, headers: headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /api/v1/seller_profile" do
    it "成功建立店家資料" do
      payload = {
        seller_profile: {
          display_name: "新商家"
        }
      }

      post api_v1_seller_profile_path, params: payload.to_json, headers: headers

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["display_name"]).to eq("新商家")
      expect(user.reload.seller_profile).to be_present
    end

    it "已有店家資料時回傳錯誤" do
      create(:seller_profile, user: user)

      post api_v1_seller_profile_path, params: { seller_profile: { display_name: "重複" } }.to_json, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["error"]).to eq("店家資料已存在")
    end
  end

  describe "DELETE /api/v1/seller_profile" do
    it "成功刪除店家資料" do
      create(:seller_profile, user: user)

      delete api_v1_seller_profile_path, headers: headers

      expect(response).to have_http_status(:ok)
      expect(user.reload.seller_profile).to be_nil
    end

    it "未找到資料時回傳 404" do
      delete api_v1_seller_profile_path, headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end
end

