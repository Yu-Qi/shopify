# ApplicationController
# 所有 Controller 的基礎類別
# 提供共用的功能，如認證、錯誤處理等

class ApplicationController < ActionController::API
  # 處理標準錯誤
  rescue_from StandardError, with: :handle_error
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :handle_validation_error

  protected

  # 取得當前用戶
  # 從 JWT token 中解析用戶
  def current_user
    @current_user ||= begin
      token = request.headers['Authorization']&.split(' ')&.last
      User.from_token(token) if token
    end
  end

  # 檢查用戶是否已登入
  def authenticate_user!
    render json: { error: '未授權' }, status: :unauthorized unless current_user
  end

  def current_seller_profile
    return unless current_user

    @current_seller_profile ||= current_user.seller_profile
  end

  def current_buyer_profile
    return unless current_user

    @current_buyer_profile ||= current_user.buyer_profile
  end

  def require_seller_profile!
    unless current_seller_profile
      render json: { error: '需要店家資料' }, status: :forbidden
      return false
    end
    true
  end

  def require_buyer_profile!
    unless current_buyer_profile
      render json: { error: '需要買家資料' }, status: :forbidden
      return false
    end
    true
  end

  # 設定當前租戶
  # 從請求參數或 headers 中取得租戶資訊
  def set_current_tenant
    tenant_id = params[:tenant_id] || request.headers['X-Tenant-Id']
    return unless tenant_id

    seller_profile = current_seller_profile
    return unless seller_profile

    @current_tenant = seller_profile.tenants.find_by(id: tenant_id)
    ActsAsTenant.current_tenant = @current_tenant
  end

  # 檢查租戶是否存在
  def ensure_tenant!
    set_current_tenant
    unless @current_tenant
      render json: { error: '租戶不存在或無權限存取' }, status: :not_found
      return false
    end
    true
  end

  # 錯誤處理
  def handle_error(exception)
    Rails.logger.error("Error: #{exception.class} - #{exception.message}")
    Rails.logger.error(exception.backtrace.join("\n"))
    render json: { error: '伺服器錯誤' }, status: :internal_server_error
  end

  # 找不到資源的錯誤處理
  def handle_not_found(exception)
    render json: { error: '資源不存在' }, status: :not_found
  end

  # 驗證錯誤處理
  def handle_validation_error(exception)
    render json: { errors: exception.record.errors.full_messages }, status: :unprocessable_entity
  end
end

