require "rails_helper"

RSpec.describe Payment, type: :model do
  subject(:payment) { build(:payment) }

  describe "associations" do
    # 付款紀錄必須有對應訂單
    it { is_expected.to belong_to(:order) }
    # 付款紀錄必須有對應買家檔案
    it { is_expected.to belong_to(:buyer_profile) }
  end

  describe "validations" do
    # 金額必填
    it { is_expected.to validate_presence_of(:amount) }
    # 金額必須大於 0
    it { is_expected.to validate_numericality_of(:amount).is_greater_than(0) }

    # 每張訂單只能有一筆付款紀錄
    it "validates uniqueness of order" do
      existing = create(:payment)
      duplicate = build(:payment, order: existing.order, buyer_profile: existing.buyer_profile)

      expect(duplicate).to be_invalid
      expect(duplicate.errors[:order_id]).to include("has already been taken")
    end

    # 限制狀態只能設定為定義過的值
    it "rejects invalid status assignment" do
      expect { payment.status = "unknown" }.to raise_error(ArgumentError)
    end
  end

  describe "enum" do
    # 確認 enum 內容與資料庫欄位型態
    it "defines statuses" do
      expect(payment).to define_enum_for(:status)
        .with_values(described_class::STATUSES)
        .backed_by_column_of_type(:string)
    end
  end
end

