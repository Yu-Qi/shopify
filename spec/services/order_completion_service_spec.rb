require "rails_helper"

RSpec.describe OrderCompletionService, type: :service do
  let(:order) { create(:order, status: Order::STATUS_SHIPPED) }

  describe "#call" do
    # 當狀態允許時應成功將訂單標記完成
    it "completes order when transition valid" do
      result = described_class.new(order).call

      expect(result[:success]).to be(true)
      expect(order.reload.status).to eq(Order::STATUS_COMPLETED)
    end

    # 狀態不允許完成時應回傳錯誤
    it "returns failure when transition invalid" do
      order.update!(status: Order::STATUS_PENDING)
      result = described_class.new(order).call

      expect(result[:success]).to be(false)
      expect(result[:errors]).to include("訂單狀態為 pending，無法完成")
      expect(result[:error_code]).to eq(ErrorCodes::Order::Completion::INVALID_STATE)
    end

    # 其他例外狀況應轉為 500 回應
    it "handles unexpected errors" do
      allow(order).to receive(:can_transition_to?).and_return(true)
      allow(order).to receive(:update!).and_raise(StandardError, "boom")

      result = described_class.new(order).call

      expect(result[:success]).to be(false)
      expect(result[:status]).to eq(:internal_server_error)
      expect(result[:error_code]).to eq(ErrorCodes::Order::Completion::UNEXPECTED_ERROR)
    end
  end
end

