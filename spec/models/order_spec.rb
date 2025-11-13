require "rails_helper"

RSpec.describe Order, type: :model do
  subject(:order) { build(:order) }

  describe "associations" do
    # 訂單必須隸屬某個商店
    it { is_expected.to belong_to(:shop) }
    # 訂單可以選擇關聯買家檔案
    it { is_expected.to belong_to(:buyer_profile).optional }
    # 刪除訂單時應連帶刪除訂單項目
    it { is_expected.to have_many(:order_items).dependent(:destroy) }
    # 訂單可透過訂單項目關聯商品
    it { is_expected.to have_many(:products).through(:order_items) }
    # 刪除訂單應一併刪除付款紀錄
    it { is_expected.to have_one(:payment).dependent(:destroy) }
  end

  describe "validations" do
    # 訂單編號必須全域唯一
    it "requires order number to be unique" do
      existing = create(:order, order_number: "ORD-TEST-123")
      duplicate = build(:order, order_number: existing.order_number)

      expect(duplicate).to be_invalid
      expect(duplicate.errors[:order_number]).to include("has already been taken")
    end

    # 總金額必須大於零
    it "requires total amount to be positive" do
      order = build(:order)
      order.order_items.each { |item| item.price = 0 }

      expect(order).to be_invalid
      expect(order.errors[:total_amount]).to include("must be greater than 0")
    end
  end

  describe "#can_transition_to?" do
    # 待處理狀態可轉為處理中
    it "allows pending to processing" do
      order = create(:order, status: Order::STATUS_PENDING)
      expect(order.can_transition_to?(Order::STATUS_PROCESSING)).to be(true)
    end

    # 已取消狀態不可再往後轉換
    it "denies cancelled from transitioning further" do
      order = create(:order, status: Order::STATUS_CANCELLED)
      expect(order.can_transition_to?(Order::STATUS_COMPLETED)).to be(false)
    end
  end

  describe "#cancel!" do
    # 不允許的狀態轉換應回傳 false
    it "returns false when transition invalid" do
      order = create(:order, status: Order::STATUS_COMPLETED)
      expect(order.cancel!).to be(false)
    end

    # 成功取消時需還原庫存並更新狀態
    it "restores stock and updates status" do
      order = create(:order, status: Order::STATUS_PENDING)
      product = order.order_items.first.product
      initial_stock = product.stock_quantity

      expect(order.cancel!).to be(true)
      expect(order.reload.status).to eq(Order::STATUS_CANCELLED)
      expect(product.reload.stock_quantity).to eq(initial_stock + order.order_items.first.quantity)
    end
  end

  describe "#complete!" do
    # 不允許的狀態轉換應回傳 false
    it "returns false when transition invalid" do
      order = create(:order, status: Order::STATUS_PENDING)
      expect(order.complete!).to be(false)
    end

    # 合法轉換應設定狀態為已完成
    it "updates status when allowed" do
      order = create(:order, status: Order::STATUS_SHIPPED)
      expect(order.complete!).to be(true)
      expect(order.reload.status).to eq(Order::STATUS_COMPLETED)
    end
  end
end

