require "rails_helper"

RSpec.describe "API::V1::BuyerProfiles", type: :request do
  let(:user) { create(:user) }
  let(:token) { "buyer-token" }
  let(:headers) do
    {
      "Authorization" => "Bearer #{token}",
      "Content-Type" => "application/json"
    }
  end

  before do
    allow(User).to receive(:from_token).and_return(user)
  end

  describe "GET /api/v1/buyer_profile" do
    context "當已有買家資料" do
      before { create(:buyer_profile, user: user, display_name: "買家 A") }

      it "回傳買家資訊" do
        get api_v1_buyer_profile_path, headers: headers

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["display_name"]).to eq("買家 A")
      end
    end

    context "當尚未建立買家資料" do
      it "回傳 404" do
        get api_v1_buyer_profile_path, headers: headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /api/v1/buyer_profile" do
    it "成功建立買家資料" do
      payload = {
        buyer_profile: {
          display_name: "新買家"
        }
      }

      post api_v1_buyer_profile_path, params: payload.to_json, headers: headers

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["display_name"]).to eq("新買家")
      expect(user.reload.buyer_profile).to be_present
    end

    it "已有買家資料時回傳錯誤" do
      create(:buyer_profile, user: user)

      post api_v1_buyer_profile_path, params: { buyer_profile: { display_name: "重複" } }.to_json, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["error"]).to eq("買家資料已存在")
    end
  end

  describe "DELETE /api/v1/buyer_profile" do
    it "成功刪除買家資料" do
      create(:buyer_profile, user: user)

      delete api_v1_buyer_profile_path, headers: headers

      expect(response).to have_http_status(:ok)
      expect(user.reload.buyer_profile).to be_nil
    end

    it "未找到資料時回傳 404" do
      delete api_v1_buyer_profile_path, headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end
end

