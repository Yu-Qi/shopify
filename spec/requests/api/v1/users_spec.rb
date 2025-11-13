require "rails_helper"

RSpec.describe "API::V1::Users", type: :request do
  let(:user) { create(:user) }
  let!(:seller_profile) { create(:seller_profile, user: user, display_name: "賣家 1") }
  let!(:buyer_profile) { create(:buyer_profile, user: user, display_name: "買家 1") }
  let(:token) { "user-token" }
  let(:headers) do
    {
      "Authorization" => "Bearer #{token}",
      "Content-Type" => "application/json"
    }
  end

  before do
    allow(User).to receive(:from_token).and_return(user)
  end

  describe "GET /api/v1/me" do
    it "回傳當前用戶資訊" do
      get api_v1_me_path, headers: headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["name"]).to eq(user.name)
      expect(body.dig("seller_profile", "display_name")).to eq("賣家 1")
      expect(body.dig("buyer_profile", "display_name")).to eq("買家 1")
    end
  end
end

