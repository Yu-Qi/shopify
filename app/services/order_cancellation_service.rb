# OrderCancellationService
# 處理訂單取消的業務邏輯
# 訂單取消需要：
# 1. 檢查訂單狀態是否可以取消
# 2. 回退庫存
# 3. 更新訂單狀態
# 4. 確保多租戶隔離

class OrderCancellationService < ApplicationService
  def initialize(order)
    @order = order
    @tenant = order.tenant
  end

  # 取消訂單
  def call
    # 檢查訂單是否可以取消
    unless @order.can_transition_to?('cancelled')
      return failure(["訂單狀態為 #{@order.status}，無法取消"])
    end

    # 使用 transaction 確保資料一致性
    # 訂單取消和庫存回退必須要麼全部成功，要麼全部失敗
    ActiveRecord::Base.transaction do
      # 設定當前租戶（確保 acts_as_tenant 正確運作）
      ActsAsTenant.current_tenant = @tenant

      # 回退庫存
      @order.order_items.each do |item|
        product = item.product
        # 使用原子操作增加庫存
        product.increment!(:stock_quantity, item.quantity)
        # 如果商品狀態是缺貨，改為正常販售
        product.update(status: 'active') if product.out_of_stock?
      end

      # 更新訂單狀態
      @order.update!(status: 'cancelled')

      success(@order)
    end
  rescue StandardError => e
    Rails.logger.error("OrderCancellationService error: #{e.message}")
    failure(["取消訂單時發生錯誤：#{e.message}"], status: :internal_server_error)
  end
end

