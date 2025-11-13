# ProductsController
# 處理商品相關的 API
# 每個商店可以有多個商品

module Api
  module V1
    class ProductsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_tenant
      before_action :set_shop
      before_action :set_product, only: [:show, :update, :destroy]

      # 取得商店的所有商品
      def index
        products = @shop.products
        render json: products, status: :ok
      end

      # 取得單一商品
      def show
        render json: @product, status: :ok
      end

      # 建立新商品
      def create
        # 使用 Service Object 處理業務邏輯
        result = ProductService.call(@shop, product_params)
        
        if result[:success]
          render json: result[:data], status: :created
        else
          render json: { errors: result[:errors] }, status: result[:status]
        end
      end

      # 更新商品
      def update
        if @product.update(product_params)
          render json: @product, status: :ok
        else
          render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # 刪除商品
      def destroy
        if @product.destroy
          render json: { message: '商品已刪除' }, status: :ok
        else
          render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
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
        @shop = @tenant.shops.find_by(id: params[:shop_id])
        unless @shop
          render json: { error: '商店不存在或無權限存取' }, status: :not_found
          return false
        end
      end

      def set_product
        # 確保商品屬於當前商店
        @product = @shop.products.find_by(id: params[:id])
        unless @product
          render json: { error: '商品不存在或無權限存取' }, status: :not_found
        end
      end

      def product_params
        params.require(:product).permit(:name, :description, :price, :stock_quantity, :sku, :status)
      end
    end
  end
end

