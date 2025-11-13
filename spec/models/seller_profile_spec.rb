require "rails_helper"

RSpec.describe SellerProfile, type: :model do
  subject(:seller_profile) { build(:seller_profile) }

  describe "associations" do
    # 賣家檔案必須隸屬某位使用者
    it { is_expected.to belong_to(:user) }
    # 刪除賣家檔案時應連帶刪除租戶
    it { is_expected.to have_many(:tenants).dependent(:destroy) }
  end

  describe "validations" do
    # 每位使用者只能擁有一個賣家檔案
    it { is_expected.to validate_uniqueness_of(:user_id) }
  end
end

