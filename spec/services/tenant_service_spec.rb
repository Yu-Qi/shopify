require "rails_helper"

RSpec.describe TenantService, type: :service do
  let(:seller_profile) { create(:seller_profile) }
  let(:params) do
    {
      name: "測試租戶",
      description: "租戶描述"
    }
  end

  describe "#call" do
    # 合法參數應建立租戶與預設商店
    it "creates tenant with default shop" do
      result = described_class.new(seller_profile, params).call

      expect(result[:success]).to be(true)
      data = result[:data]
      expect(data[:tenant]).to be_persisted
      expect(data[:default_shop]).to be_persisted
      expect(data[:tenant].seller_profile).to eq(seller_profile)
      expect(data[:default_shop].name).to eq("#{params[:name]} 主商店")
    end

    # 無效參數應回傳驗證錯誤
    it "returns validation errors for invalid params" do
      invalid_params = params.merge(name: nil)
      result = described_class.new(seller_profile, invalid_params).call

      expect(result[:success]).to be(false)
      expect(result[:errors]).to include("Name can't be blank")
      expect(result[:error_code]).to eq(ErrorCodes::Tenant::VALIDATION_FAILED)
    end

    # 發生未預期例外時應回傳 500
    it "handles unexpected errors" do
      allow(seller_profile).to receive_message_chain(:tenants, :build).and_raise(StandardError, "boom")
      result = described_class.new(seller_profile, params).call

      expect(result[:success]).to be(false)
      expect(result[:status]).to eq(:internal_server_error)
      expect(result[:error_code]).to eq(ErrorCodes::Tenant::UNEXPECTED_ERROR)
    end
  end
end

