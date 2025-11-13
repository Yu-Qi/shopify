# HealthController
# 健康檢查端點
# 用於監控系統狀態

class HealthController < ApplicationController
  # 跳過認證檢查（健康檢查端點不需要認證）
  skip_before_action :authenticate_user!, raise: false

  def check
    # 檢查資料庫連線
    ActiveRecord::Base.connection.execute("SELECT 1")
    
    render json: {
      status: 'ok',
      timestamp: Time.current.iso8601,
      database: 'connected'
    }, status: :ok
  rescue StandardError => e
    render json: {
      status: 'error',
      timestamp: Time.current.iso8601,
      error: e.message
    }, status: :service_unavailable
  end
end

