# ShopsController
# 處理商店相關的 API
# 每個租戶可以有多個商店

module Api
  module V1
    class ShopsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_tenant
      before_action :set_shop, only: [:show, :update, :destroy]

      # 取得租戶的所有商店
      def index
        shops = @tenant.shops
        render json: shops, status: :ok
      end

      # 取得單一商店
      def show
        render json: @shop, status: :ok
      end

      # 建立新商店
      def create
        # 使用 Service Object 處理業務邏輯
        result = ShopService.call(@tenant, shop_params)
        
        if result[:success]
          render json: result[:data], status: :created
        else
          render json: { errors: result[:errors] }, status: result[:status]
        end
      end

      # 更新商店
      def update
        if @shop.update(shop_params)
          render json: @shop, status: :ok
        else
          render json: { errors: @shop.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # 刪除商店
      def destroy
        if @shop.destroy
          render json: { message: '商店已刪除' }, status: :ok
        else
          render json: { errors: @shop.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_tenant
        # 確保只能存取自己的租戶
        @tenant = current_user.tenants.find_by(id: params[:tenant_id])
        unless @tenant
          render json: { error: '租戶不存在或無權限存取' }, status: :not_found
          return false
        end
        # 設定當前租戶（確保 acts_as_tenant 正確運作）
        ActsAsTenant.current_tenant = @tenant
      end

      def set_shop
        # 確保商店屬於當前租戶
        @shop = @tenant.shops.find_by(id: params[:id])
        unless @shop
          render json: { error: '商店不存在或無權限存取' }, status: :not_found
        end
      end

      def shop_params
        params.require(:shop).permit(:name, :description, :status)
      end
    end
  end
end

