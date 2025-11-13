# ShopsController
# 處理商店相關的 API
# 每個租戶可以有多個商店

module Api
  module V1
    class ShopsController < ApplicationController
      before_action :authenticate_user!
      before_action :require_seller_profile!
      before_action :ensure_tenant!, only: [:index, :create]
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

      def set_shop
        # 確保商店屬於目前使用者的租戶
        @shop = Shop.joins(:tenant)
                    .where(id: params[:id], tenants: { seller_profile_id: current_seller_profile.id })
                    .first
        unless @shop
          render json: { error: '商店不存在或無權限存取' }, status: :not_found
          return false
        end
        @tenant = @shop.tenant
        ActsAsTenant.current_tenant = @tenant
      end

      def ensure_tenant!
        return false unless super

        @tenant = @current_tenant
        true
      end

      def shop_params
        params.require(:shop).permit(:name, :description, :status)
      end
    end
  end
end

