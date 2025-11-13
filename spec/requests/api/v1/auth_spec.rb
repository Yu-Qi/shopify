require "rails_helper"

RSpec.describe "API::V1::Auth", type: :request do
  let(:headers) { { "Content-Type" => "application/json" } }
  let(:secret_key_base) { "test-secret-key" }

  before do
    allow(Rails.application).to receive(:credentials).and_return(double(secret_key_base: secret_key_base))
  end

  describe "POST /api/v1/auth/register" do
    it "成功註冊並回傳 token" do
      payload = {
        user: {
          name: "新用戶",
          email: "new_user@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }

      expect do
        post api_v1_auth_register_path, params: payload.to_json, headers: headers
      end.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["message"]).to eq("註冊成功")
      expect(body["token"]).to be_present
    end

    it "當資料無效時回傳錯誤" do
      payload = {
        user: {
          name: "錯誤用戶",
          email: "invalid_email",
          password: "short",
          password_confirmation: "mismatch"
        }
      }

      post api_v1_auth_register_path, params: payload.to_json, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["errors"]).to be_present
    end
  end

  describe "POST /api/v1/auth/login" do
    let!(:user) { create(:user, email: "login@example.com", password: "password123") }

    it "登入成功回傳 token" do
      payload = {
        user: {
          email: "login@example.com",
          password: "password123"
        }
      }

      post api_v1_auth_login_path, params: payload.to_json, headers: headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["message"]).to eq("登入成功")
      expect(body["token"]).to be_present
    end

    it "登入失敗回傳未授權" do
      payload = {
        user: {
          email: "login@example.com",
          password: "wrong"
        }
      }

      post api_v1_auth_login_path, params: payload.to_json, headers: headers

      expect(response).to have_http_status(:unauthorized)
      body = JSON.parse(response.body)
      expect(body["error"]).to eq("電子郵件或密碼錯誤")
    end
  end

  describe "POST /api/v1/auth/logout" do
    let(:user) { create(:user) }
    let(:token) { "test-token" }

    before do
      allow(User).to receive(:from_token).with(token).and_return(user)
    end

    it "登出成功回傳訊息" do
      post api_v1_auth_logout_path, headers: headers.merge("Authorization" => "Bearer #{token}")

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["message"]).to eq("登出成功")
    end
  end
end

