require "rails_helper"

RSpec.describe BuyerProfile, type: :model do
  subject(:buyer_profile) { build(:buyer_profile) }

  describe "associations" do
    # 買家檔案必須隸屬某位使用者
    it { is_expected.to belong_to(:user) }
    # 刪除買家檔案時應連帶刪除付款紀錄
    it { is_expected.to have_many(:payments).dependent(:destroy) }
  end

  describe "validations" do
    # 每位使用者只能擁有一個買家檔案
    it { is_expected.to validate_uniqueness_of(:user_id) }
  end
end

