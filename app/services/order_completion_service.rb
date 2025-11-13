# OrderCompletionService
# 處理訂單完成的業務邏輯
# 訂單完成需要：
# 1. 檢查訂單狀態是否可以完成
# 2. 更新訂單狀態
# 3. 可以觸發相關事件（如發送通知、更新統計等）

class OrderCompletionService < ApplicationService
  def initialize(order)
    @order = order
    @tenant = order.tenant
  end

  # 完成訂單
  def call
    # 檢查訂單是否可以完成
    unless @order.can_transition_to?('completed')
      return failure(["訂單狀態為 #{@order.status}，無法完成"])
    end

    # 使用 transaction 確保資料一致性
    ActiveRecord::Base.transaction do
      # 設定當前租戶（確保 acts_as_tenant 正確運作）
      ActsAsTenant.current_tenant = @tenant

      # 更新訂單狀態
      @order.update!(status: 'completed')

      # 這裡可以觸發其他業務邏輯，例如：
      # - 發送完成通知給客戶
      # - 更新商店的銷售統計
      # - 觸發庫存補貨提醒
      # 這些可以透過 Sidekiq 背景任務處理，避免影響主流程效能

      success(@order)
    end
  rescue StandardError => e
    Rails.logger.error("OrderCompletionService error: #{e.message}")
    failure(["完成訂單時發生錯誤：#{e.message}"], status: :internal_server_error)
  end
end

