require "rails_helper"

RSpec.describe ShopService, type: :service do
  let(:tenant) { create(:tenant) }
  let(:params) do
    {
      name: "新商店",
      description: "這是測試商店",
      status: Shop::STATUS_ACTIVE
    }
  end

  describe "#call" do
    # 合法參數應成功建立商店
    it "creates shop successfully" do
      result = described_class.new(tenant, params).call

      expect(result[:success]).to be(true)
      shop = result[:data]
      expect(shop).to be_persisted
      expect(shop.tenant).to eq(tenant)
    end

    # 無效參數應回傳驗證錯誤
    it "returns validation errors when invalid" do
      invalid_params = params.merge(name: nil)
      result = described_class.new(tenant, invalid_params).call

      expect(result[:success]).to be(false)
      expect(result[:errors]).to include("Name can't be blank")
      expect(result[:error_code]).to eq(ErrorCodes::Shop::VALIDATION_FAILED)
    end

    # 發生未預期例外時應回傳 500
    it "handles unexpected errors" do
      allow(tenant).to receive_message_chain(:shops, :build).and_raise(StandardError, "boom")
      result = described_class.new(tenant, params).call

      expect(result[:success]).to be(false)
      expect(result[:status]).to eq(:internal_server_error)
      expect(result[:error_code]).to eq(ErrorCodes::Shop::UNEXPECTED_ERROR)
    end
  end
end

