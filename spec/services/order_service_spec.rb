require "rails_helper"

RSpec.describe OrderService, type: :service do
  let(:tenant) { create(:tenant) }
  let(:shop) { create(:shop, tenant: tenant, status: Shop::STATUS_ACTIVE) }
  let(:product) { create(:product, shop: shop, stock_quantity: 5, price: BigDecimal("100.0")) }
  let(:buyer_profile) { create(:buyer_profile) }
  let(:base_params) do
    {
      customer_name: "王小明",
      customer_email: "customer@example.com",
      shipping_address: "台北市信義區市府路1號",
      order_items: [
        { product_id: product.id, quantity: 2 }
      ]
    }
  end

  describe "#call" do
    # 正常情況應建立訂單並扣除庫存
    it "creates an order and reduces product stock" do
      result = described_class.new(shop, base_params, buyer_profile: buyer_profile).call

      expect(result[:success]).to be(true)
      order = result[:data]
      expect(order).to be_persisted
      expect(order.order_items.first.quantity).to eq(2)
      expect(order.total_amount).to eq(BigDecimal("200.0"))
      expect(order.buyer_profile).to eq(buyer_profile)
      expect(product.reload.stock_quantity).to eq(3)
    end

    # 商店無法接單時應回傳錯誤
    it "returns error when shop cannot receive orders" do
      shop.update!(status: Shop::STATUS_INACTIVE)
      result = described_class.new(shop, base_params).call

      expect(result).to eq(
        success: false,
        errors: ["商店目前無法接收訂單"],
        status: :unprocessable_entity,
        error_code: ErrorCodes::Order::SHOP_NOT_READY
      )
    end

    # 訂單數量非正整數時應回傳錯誤
    it "returns error when quantity invalid" do
      params = base_params.merge(order_items: [{ product_id: product.id, quantity: 0 }])
      result = described_class.new(shop, params).call

      expect(result[:success]).to be(false)
      expect(result[:errors]).to include("商品 #{product.name} 數量必須大於 0")
      expect(result[:error_code]).to eq(ErrorCodes::Order::INVENTORY_NOT_AVAILABLE)
    end

    # 當商品不屬於同一租戶時應拒絕
    it "returns error when product not in tenant scope" do
      other_product = create(:product)
      params = base_params.merge(order_items: [{ product_id: other_product.id, quantity: 1 }])

      allow(Product).to receive(:find).with(other_product.id).and_return(other_product)
      result = described_class.new(shop, params).call

      expect(result[:success]).to be(false)
      expect(result[:errors]).to include("商品不存在或無權限存取")
    end

    # 庫存不足時應回傳錯誤
    it "returns error when stock insufficient" do
      params = base_params.merge(order_items: [{ product_id: product.id, quantity: 10 }])
      result = described_class.new(shop, params).call

      expect(result[:success]).to be(false)
      expect(result[:errors]).to include("商品 #{product.name} 庫存不足（目前庫存：5，需要：10）")
    end

    # 商品已標記缺貨時應拒絕建立訂單
    it "returns error when product already out of stock" do
      product.update!(stock_quantity: 0, status: Product::STATUS_OUT_OF_STOCK)
      result = described_class.new(shop, base_params).call

      expect(result[:success]).to be(false)
      expect(result[:errors]).to include("商品 #{product.name} 目前無庫存")
    end
  end
end

