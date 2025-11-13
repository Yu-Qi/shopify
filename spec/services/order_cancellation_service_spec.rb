require "rails_helper"

RSpec.describe OrderCancellationService, type: :service do
  let(:order) { create(:order, status: Order::STATUS_PENDING) }

  describe "#call" do
    # 成功取消訂單時應還原庫存並更新狀態
    it "cancels order and restores inventory" do
      product = order.order_items.first.product
      initial_stock = product.stock_quantity

      result = described_class.new(order).call

      expect(result[:success]).to be(true)
      expect(order.reload.status).to eq(Order::STATUS_CANCELLED)
      expect(product.reload.stock_quantity).to eq(initial_stock + order.order_items.first.quantity)
    end

    # 不能取消的狀態應回傳錯誤訊息
    it "returns failure when order cannot be cancelled" do
      order.update!(status: Order::STATUS_COMPLETED)
      result = described_class.new(order).call

      expect(result[:success]).to be(false)
      expect(result[:errors]).to include("訂單狀態為 completed，無法取消")
      expect(result[:error_code]).to eq(ErrorCodes::Order::Cancellation::INVALID_STATE)
    end

    # 當庫存回補發生錯誤時應捕捉並回報
    it "handles stock adjustment errors" do
      allow(order).to receive(:can_transition_to?).and_return(true)
      allow(order).to receive(:cancel!).and_raise(Product::StockAdjustmentError, "錯誤")
      result = described_class.new(order).call

      expect(result[:success]).to be(false)
      expect(result[:errors]).to include("錯誤")
      expect(result[:error_code]).to eq(ErrorCodes::Order::Cancellation::UNEXPECTED_ERROR)
    end

    # 其他未預期錯誤應回傳 500 狀態
    it "handles unexpected errors" do
      allow(order).to receive(:can_transition_to?).and_return(true)
      allow(order).to receive(:cancel!).and_raise(StandardError, "boom")
      result = described_class.new(order).call

      expect(result[:success]).to be(false)
      expect(result[:status]).to eq(:internal_server_error)
      expect(result[:error_code]).to eq(ErrorCodes::Order::Cancellation::UNEXPECTED_ERROR)
    end
  end
end

