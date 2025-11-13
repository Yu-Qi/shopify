require "rails_helper"

RSpec.describe ProductService, type: :service do
  let(:shop) { create(:shop) }
  let(:params) do
    {
      name: "新商品",
      description: "測試商品",
      price: 199.99,
      stock_quantity: 5,
      sku: "SKU-001",
      status: Product::STATUS_ACTIVE
    }
  end

  describe "#call" do
    # 合法參數應成功建立商品
    it "creates product successfully" do
      result = described_class.new(shop, params).call

      expect(result[:success]).to be(true)
      product = result[:data]
      expect(product).to be_persisted
      expect(product.shop).to eq(shop)
    end

    # 無效參數應回傳驗證錯誤
    it "returns validation errors for invalid params" do
      invalid_params = params.merge(price: nil)
      result = described_class.new(shop, invalid_params).call

      expect(result[:success]).to be(false)
      expect(result[:errors]).to include("Price can't be blank")
      expect(result[:error_code]).to eq(ErrorCodes::Product::VALIDATION_FAILED)
    end

    # 發生未預期例外時應回傳 500
    it "handles unexpected errors" do
      allow(shop).to receive_message_chain(:products, :build).and_raise(StandardError, "boom")
      result = described_class.new(shop, params).call

      expect(result[:success]).to be(false)
      expect(result[:status]).to eq(:internal_server_error)
      expect(result[:error_code]).to eq(ErrorCodes::Product::UNEXPECTED_ERROR)
    end
  end
end

