# ProductService
# 處理商品相關的業務邏輯
# 確保商品的建立和管理符合多租戶隔離原則

class ProductService < ApplicationService
  def initialize(shop, params)
    @shop = shop
    @tenant = shop.tenant
    @params = params
  end

  # 建立新的商品
  def call
    # 使用 transaction 確保資料一致性
    ActiveRecord::Base.transaction do
      # 設定當前租戶（確保 acts_as_tenant 正確運作）
      ActsAsTenant.current_tenant = @tenant
      
      # 建立商品
      product = @shop.products.build(@params)
      
      if product.save
        success(product)
      else
        failure(product.errors.full_messages)
      end
    end
  rescue StandardError => e
    Rails.logger.error("ProductService error: #{e.message}")
    failure(["建立商品時發生錯誤：#{e.message}"], status: :internal_server_error)
  end
end

