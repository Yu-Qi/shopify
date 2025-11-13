# TenantService
# 處理租戶相關的業務邏輯
# 在多租戶場景下，確保租戶資料的正確建立和管理

class TenantService < ApplicationService
  def initialize(user, params)
    @user = user
    @params = params
  end

  # 建立新的租戶（電商平台）
  def call
    # 使用 transaction 確保資料一致性
    ActiveRecord::Base.transaction do
      # 建立租戶
      tenant = @user.tenants.build(@params)
      
      # 驗證並儲存
      if tenant.save
        # 建立租戶時，可以同時建立一個預設商店
        # 這是一個實務場景：建立電商平台時通常會有一個主商店
        default_shop = tenant.shops.create!(
          name: "#{tenant.name} 主商店",
          description: "預設商店",
          status: 'active'
        )
        
        success({ tenant: tenant, default_shop: default_shop })
      else
        failure(tenant.errors.full_messages)
      end
    end
  rescue StandardError => e
    # 錯誤處理：記錄錯誤並回傳失敗訊息
    Rails.logger.error("TenantService error: #{e.message}")
    failure(["建立租戶時發生錯誤：#{e.message}"], status: :internal_server_error)
  end
end

