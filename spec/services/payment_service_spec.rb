require "rails_helper"

RSpec.describe PaymentService, type: :service do
  let(:order) { create(:order, status: Order::STATUS_PENDING, buyer_profile: nil) }
  let(:buyer_profile) { create(:buyer_profile) }
  let(:valid_params) do
    {
      amount: order.total_amount.to_s,
      payment_method: "credit_card",
      transaction_reference: "TXN-123",
      metadata: { channel: "web" }
    }
  end

  describe "#call" do
    # 付款成功時應建立紀錄並將訂單轉為處理中
    it "creates payment and updates order status" do
      result = described_class.new(order, buyer_profile, valid_params).call

      expect(result[:success]).to be(true)
      payment = result[:data]
      expect(payment).to be_persisted
      expect(payment.amount).to eq(order.total_amount)
      expect(order.reload.status).to eq(Order::STATUS_PROCESSING)
      expect(order.buyer_profile).to eq(buyer_profile)
    end

    # 已存在付款紀錄時應拒絕重複付款
    it "fails when order already paid" do
      create(:payment, order: order, buyer_profile: buyer_profile)
      result = described_class.new(order.reload, buyer_profile, valid_params).call

      expect(result[:success]).to be(false)
      expect(result[:error_code]).to eq(ErrorCodes::Order::Payment::ALREADY_PAID)
    end

    # 訂單不在可付款狀態時應回傳錯誤
    it "fails when order in invalid state" do
      order.update!(status: Order::STATUS_COMPLETED)
      result = described_class.new(order, buyer_profile, valid_params).call

      expect(result[:success]).to be(false)
      expect(result[:error_code]).to eq(ErrorCodes::Order::Payment::INVALID_STATE)
    end

    # 付款人與訂單綁定的買家不一致時應拒絕
    it "fails when buyer unauthorized" do
      other_profile = create(:buyer_profile)
      order.update!(buyer_profile: other_profile)
      result = described_class.new(order, buyer_profile, valid_params).call

      expect(result[:success]).to be(false)
      expect(result[:error_code]).to eq(ErrorCodes::Order::Payment::UNAUTHORIZED)
    end

    # 付款金額與訂單金額不符時應回傳錯誤
    it "fails when amount mismatch" do
      params = valid_params.merge(amount: (order.total_amount + 1))
      result = described_class.new(order, buyer_profile, params).call

      expect(result[:success]).to be(false)
      expect(result[:error_code]).to eq(ErrorCodes::Order::Payment::INVALID_AMOUNT)
    end

    # 當資料驗證失敗時應回傳表單錯誤
    it "returns validation errors" do
      invalid_payment = Payment.new
      invalid_payment.errors.add(:amount, "must be greater than 0")
      allow(Payment).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(invalid_payment))

      result = described_class.new(order, buyer_profile, valid_params).call

      expect(result[:success]).to be(false)
      expect(result[:errors]).to include("Amount must be greater than 0")
    end

    # 其他未預期錯誤需回傳 500 狀態
    it "handles unexpected errors" do
      allow(Payment).to receive(:create!).and_raise(StandardError, "boom")
      result = described_class.new(order, buyer_profile, valid_params).call

      expect(result[:success]).to be(false)
      expect(result[:status]).to eq(:internal_server_error)
      expect(result[:error_code]).to eq(ErrorCodes::Order::Payment::UNEXPECTED_ERROR)
    end
  end
end

