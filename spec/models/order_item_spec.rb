require "rails_helper"

RSpec.describe OrderItem, type: :model do
  describe "associations" do
    # 建立訂單項目時應綁定訂單與商品
    it "belongs to an order and product" do
      order_item = create(:order_item)
      expect(order_item.order).to be_present
      expect(order_item.product).to be_present
    end
  end

  describe "validations" do
    # 數量必須大於 0
    it "requires quantity to be positive" do
      order_item = build(:order_item, quantity: 0)
      expect(order_item).to be_invalid
      expect(order_item.errors[:quantity]).to include("must be greater than 0")
    end

    # 單價必須大於 0
    it "requires price to be positive" do
      order_item = build(:order_item, price: -1)
      expect(order_item).to be_invalid
      expect(order_item.errors[:price]).to include("must be greater than 0")
    end
  end

  describe "#subtotal" do
    # 小計應為單價乘以數量
    it "returns price multiplied by quantity" do
      order_item = build(:order_item, price: 10, quantity: 3)
      expect(order_item.subtotal).to eq(30)
    end
  end

  describe "callbacks" do
    # 若未指定單價，應在建立時帶入商品當下價格
    it "copies price from product on create" do
      product = create(:product, price: 25)
      order = create(:order, shop: product.shop)

      order_item = nil
      ActsAsTenant.with_tenant(product.shop.tenant) do
        order_item = create(:order_item, order: order, product: product, price: nil)
      end

      expect(order_item.price).to eq(product.price)
    end
  end
end

