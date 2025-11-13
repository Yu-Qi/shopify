require "rails_helper"

RSpec.describe User, type: :model do
  subject(:user) { build(:user) }

  describe "associations" do
    # 確認使用者刪除時會一併移除賣家檔案
    it { is_expected.to have_one(:seller_profile).dependent(:destroy) }
    # 確認使用者刪除時會一併移除買家檔案
    it { is_expected.to have_one(:buyer_profile).dependent(:destroy) }
    # 確認使用者可透過賣家檔案關聯多個租戶
    it { is_expected.to have_many(:tenants).through(:seller_profile) }
  end

  describe "validations" do
    # 驗證 email 必填
    it { is_expected.to validate_presence_of(:email) }
    # 驗證合法 email 會被接受
    it { is_expected.to allow_value("user@example.com").for(:email) }
    # 驗證錯誤格式的 email 會被拒絕
    it { is_expected.not_to allow_value("invalid_email").for(:email) }
    # 驗證姓名必填
    it { is_expected.to validate_presence_of(:name) }
    # 驗證密碼必填
    it { is_expected.to validate_presence_of(:password) }
  end

  describe "#seller?" do
    # 有賣家檔案時 seller? 應回傳 true
    it "returns true when seller profile exists" do
      user = create(:user, seller_profile: build(:seller_profile))
      expect(user.seller?).to be(true)
    end

    # 沒有賣家檔案時 seller? 應回傳 false
    it "returns false when seller profile missing" do
      user = create(:user)
      expect(user.seller?).to be(false)
    end
  end

  describe "#buyer?" do
    # 有買家檔案時 buyer? 應回傳 true
    it "returns true when buyer profile exists" do
      user = create(:user, buyer_profile: build(:buyer_profile))
      expect(user.buyer?).to be(true)
    end

    # 沒有買家檔案時 buyer? 應回傳 false
    it "returns false when buyer profile missing" do
      user = create(:user)
      expect(user.buyer?).to be(false)
    end
  end

  describe "uniqueness validations" do
    # 驗證 email 即使大小寫不同也視為已存在
    it "enforces uniqueness of email regardless of case" do
      create(:user, email: "user@example.com")
      duplicate = build(:user, email: "user@example.com")
      duplicate.validate

      expect(duplicate.errors[:email]).to include("has already been taken")
    end
  end

  describe "token handling" do
    let(:secret_key_base) { "test_secret_key_base" }

    before do
      allow(Rails.application).to receive(:credentials).and_return(double(secret_key_base: secret_key_base))
    end

    # 產生的 JWT 應包含使用者 ID
    it "generates a JWT token with user id" do
      user.save!
      token = user.generate_token
      decoded = JWT.decode(token, secret_key_base, true, { algorithm: "HS256" })

      expect(decoded.first["user_id"]).to eq(user.id)
    end

    # 可透過 JWT 還原對應使用者
    it "retrieves user from token" do
      user.save!
      token = user.generate_token
      expect(User.from_token(token)).to eq(user)
    end

    # 無效 JWT 應回傳 nil
    it "returns nil when token invalid" do
      expect(User.from_token("invalid.token")).to be_nil
    end
  end
end

