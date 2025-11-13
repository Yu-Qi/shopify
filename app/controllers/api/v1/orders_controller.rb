# OrdersController
# 處理訂單相關的 API
# 每個商店可以有多個訂單

module Api
  module V1
    class OrdersController < ApplicationController
      before_action :authenticate_user!
      before_action :require_seller_profile!
      before_action :set_tenant
      before_action :set_shop
      before_action :set_order, only: [:show, :update, :cancel, :complete]

      # 取得商店的所有訂單
      def index
        orders = @shop.orders.includes(:order_items, :products)
        render json: orders, status: :ok
      end

      # 取得單一訂單
      def show
        render json: @order, include: [:order_items, :products], status: :ok
      end

      # 建立新訂單
      def create
        # 使用 Service Object 處理業務邏輯
        # 訂單建立涉及庫存檢查和扣減，邏輯較複雜，使用 Service Object 可以更好地管理
        result = OrderService.call(@shop, order_params)
        
        if result[:success]
          render json: result[:data], include: [:order_items, :products], status: :created
        else
          render json: { errors: result[:errors] }, status: result[:status]
        end
      end

      # 更新訂單
      def update
        if @order.update(order_params.except(:order_items))
          render json: @order, include: [:order_items, :products], status: :ok
        else
          render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # 取消訂單
      def cancel
        # 使用 Service Object 處理訂單取消邏輯
        # 訂單取消需要回退庫存，使用 Service Object 可以更好地管理
        result = OrderCancellationService.call(@order)
        
        if result[:success]
          render json: result[:data], include: [:order_items, :products], status: :ok
        else
          render json: { errors: result[:errors] }, status: result[:status]
        end
      end

      # 完成訂單
      def complete
        # 使用 Service Object 處理訂單完成邏輯
        result = OrderCompletionService.call(@order)
        
        if result[:success]
          render json: result[:data], include: [:order_items, :products], status: :ok
        else
          render json: { errors: result[:errors] }, status: result[:status]
        end
      end

      private

      def set_tenant
        # 確保只能存取自己的租戶
        @tenant = current_seller_profile.tenants.find_by(id: params[:tenant_id])
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

      def set_order
        # 確保訂單屬於當前商店
        @order = @shop.orders.find_by(id: params[:id])
        unless @order
          render json: { error: '訂單不存在或無權限存取' }, status: :not_found
        end
      end

      def order_params
        params.require(:order).permit(:customer_name, :customer_email, :shipping_address, order_items: [:product_id, :quantity])
      end
    end
  end
end

