require "rails_helper"

RSpec.describe Tenant, type: :model do
  subject(:tenant) { build(:tenant) }

  describe "associations" do
    # 租戶必須隸屬某一個賣家檔案
    it { is_expected.to belong_to(:seller_profile) }
    # 刪除租戶時應一併刪除所有商店
    it { is_expected.to have_many(:shops).dependent(:destroy) }
  end

  describe "validations" do
    # 驗證租戶名稱必填
    it { is_expected.to validate_presence_of(:name) }
    # 同一賣家底下租戶名稱不可重複
    it do
      create(:tenant, seller_profile: tenant.seller_profile, name: tenant.name)
      expect(tenant).to validate_uniqueness_of(:name).scoped_to(:seller_profile_id)
    end

    # 網域名稱必須唯一
    it "validates uniqueness of domain" do
      create(:tenant, domain: "my-tenant.com")
      tenant.domain = "my-tenant.com"

      expect(tenant).to be_invalid
      expect(tenant.errors[:domain]).to include("has already been taken")
    end
  end

  describe "callbacks" do
    # 若未指定 subdomain 應自動生成
    it "generates subdomain automatically" do
      allow(SecureRandom).to receive(:hex).and_call_original
      tenant.subdomain = nil
      tenant.save!
      expect(tenant.subdomain).to be_present
    end

    # 自動生成的 subdomain 應確保唯一性
    it "ensures uniqueness of generated subdomain" do
      allow(SecureRandom).to receive(:hex).and_return("abcd")
      create(:tenant, name: "Existing Tenant", subdomain: "another-tenant")

      new_tenant = build(:tenant, name: "Another Tenant")
      new_tenant.save!
      expect(new_tenant.subdomain).not_to eq("another-tenant")
      expect(new_tenant.subdomain).to start_with("another-tenant-abcd")
    end
  end
end

