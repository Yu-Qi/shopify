# ShopService
# 處理商店相關的業務邏輯
# 確保商店的建立和管理符合多租戶隔離原則

class ShopService < ApplicationService
  def initialize(tenant, params)
    @tenant = tenant
    @params = params
  end

  # 建立新的商店
  def call
    # 使用 transaction 確保資料一致性
    ActiveRecord::Base.transaction do
      # 設定當前租戶（確保 acts_as_tenant 正確運作）
      ActsAsTenant.current_tenant = @tenant
      
      # 建立商店
      shop = @tenant.shops.build(@params)
      
      if shop.save
        success(shop)
      else
        failure(shop.errors.full_messages, code: ErrorCodes::Shop::VALIDATION_FAILED)
      end
    end
  rescue StandardError => e
    Rails.logger.error("ShopService error: #{e.message}")
    failure(
      ["建立商店時發生錯誤：#{e.message}"],
      status: :internal_server_error,
      code: ErrorCodes::Shop::UNEXPECTED_ERROR
    )
  end
end

