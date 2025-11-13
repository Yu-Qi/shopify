# TenantsController
# 處理租戶相關的 API
# 用戶可以建立和管理自己的電商平台（租戶）

module Api
  module V1
    class TenantsController < ApplicationController
      before_action :authenticate_user!
      before_action :require_seller_profile!
      before_action :set_tenant, only: [:show, :update, :destroy]

      # 取得當前用戶的所有租戶
      def my_tenants
        tenants = current_seller_profile.tenants
        render json: tenants, status: :ok
      end

      # 取得所有租戶（當前用戶的）
      def index
        tenants = current_seller_profile.tenants
        render json: tenants, status: :ok
      end

      # 取得單一租戶
      def show
        render json: @tenant, status: :ok
      end

      # 建立新租戶
      def create
        # 使用 Service Object 處理業務邏輯
        result = TenantService.call(current_seller_profile, tenant_params)
        
        if result[:success]
          render json: result[:data], status: :created
        else
          render json: { errors: result[:errors] }, status: result[:status]
        end
      end

      # 更新租戶
      def update
        if @tenant.update(tenant_params)
          render json: @tenant, status: :ok
        else
          render json: { errors: @tenant.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # 刪除租戶
      def destroy
        if @tenant.destroy
          render json: { message: '租戶已刪除' }, status: :ok
        else
          render json: { errors: @tenant.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_tenant
        # 確保只能存取自己的租戶
        @tenant = current_seller_profile.tenants.find_by(id: params[:id])
        unless @tenant
          render json: { error: '租戶不存在或無權限存取' }, status: :not_found
        end
      end

      def tenant_params
        params.require(:tenant).permit(:name, :description, :domain)
      end
    end
  end
end

