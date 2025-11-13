require "rails_helper"

RSpec.describe Shop, type: :model do
  subject(:shop) { build(:shop) }

  describe "associations" do
    # 商店必須隸屬某個租戶
    it { is_expected.to belong_to(:tenant) }
    # 刪除商店時應一併清除商品
    it { is_expected.to have_many(:products).dependent(:destroy) }
    # 刪除商店時應一併清除訂單
    it { is_expected.to have_many(:orders).dependent(:destroy) }
  end

  describe "validations" do
    # 商店名稱必填
    it { is_expected.to validate_presence_of(:name) }

    # 同一租戶下商店名稱不可重複
    it "validates uniqueness of name scoped to tenant" do
      create(:shop, tenant: shop.tenant, name: "Main Shop")
      duplicate = build(:shop, tenant: shop.tenant, name: "Main Shop")

      expect(duplicate).to be_invalid
      expect(duplicate.errors[:name]).to include("has already been taken")
    end

    # 可接受的狀態應通過驗證
    it "accepts valid statuses" do
      shop.status = Shop::STATUS_ACTIVE
      expect(shop).to be_valid
    end

    # 非列舉狀態應觸發錯誤
    it "rejects invalid statuses" do
      expect { shop.status = "unknown" }.to raise_error(ArgumentError)
    end
  end

  describe "#can_receive_orders?" do
    # 當狀態為啟用時可接單
    it "returns true when status is active" do
      shop.status = Shop::STATUS_ACTIVE
      expect(shop.can_receive_orders?).to be(true)
    end

    # 當狀態非啟用時不可接單
    it "returns false when status not active" do
      shop.status = Shop::STATUS_INACTIVE
      expect(shop.can_receive_orders?).to be(false)
    end
  end
end

