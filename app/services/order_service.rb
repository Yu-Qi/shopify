# OrderService
# 處理訂單相關的業務邏輯
# 這是比較複雜的業務邏輯，需要處理：
# 1. 訂單建立
# 2. 庫存檢查和扣減
# 3. 訂單狀態管理
# 4. 多租戶隔離

class OrderService < ApplicationService
  def initialize(shop, params, buyer_profile: nil)
    @shop = shop
    @tenant = shop.tenant
    @params = params
    @order_items_params = params[:order_items] || []
    @buyer_profile = buyer_profile
  end

  # 建立新訂單
  def call
    # 檢查商店是否可以接收訂單
    return failure(["商店目前無法接收訂單"], code: ErrorCodes::Order::SHOP_NOT_READY) unless @shop.can_receive_orders?

    # 使用 transaction 確保資料一致性
    # 這很重要：訂單建立、庫存扣減必須要麼全部成功，要麼全部失敗
    ActiveRecord::Base.transaction do
      # 設定當前租戶（確保 acts_as_tenant 正確運作）
      ActsAsTenant.current_tenant = @tenant

      # 驗證庫存
      inventory_check_result = check_inventory
      return inventory_check_result unless inventory_check_result[:success]

      # 建立訂單
      order_attributes = {
        customer_name: @params[:customer_name],
        customer_email: @params[:customer_email],
        shipping_address: @params[:shipping_address],
        status: Order::STATUS_PENDING
      }
      order_attributes[:buyer_profile] = @buyer_profile if @buyer_profile

      order = @shop.orders.build(order_attributes)

      # 建立訂單項目並扣減庫存
      @order_items_params.each do |item_params|
        product = Product.find(item_params[:product_id])
        quantity = item_params[:quantity].to_i

        # 建立訂單項目
        order_item = order.order_items.build(
          product: product,
          quantity: quantity,
          price: product.price
        )

        # 扣減庫存（原子操作，確保併發安全）
        product.decrease_stock!(quantity)
      end

      # 計算總金額並儲存訂單
      order.save!

      success(order)
    end
  rescue Product::InsufficientStockError => e
    failure([e.message], code: ErrorCodes::Order::INVENTORY_NOT_AVAILABLE)
  rescue Product::InvalidStockQuantityError => e
    failure([e.message], code: ErrorCodes::Order::VALIDATION_FAILED)
  rescue Product::StockAdjustmentError => e
    failure([e.message], code: ErrorCodes::Order::UNEXPECTED_ERROR)
  rescue ActiveRecord::RecordInvalid => e
    failure([e.message], code: ErrorCodes::Order::VALIDATION_FAILED)
  rescue StandardError => e
    Rails.logger.error("OrderService error: #{e.message}")
    failure(["建立訂單時發生錯誤：#{e.message}"], status: :internal_server_error, code: ErrorCodes::Order::UNEXPECTED_ERROR)
  end

  private

  # 檢查庫存是否足夠
  # 在建立訂單前，先檢查所有商品的庫存是否足夠
  def check_inventory
    # TODO: transaction 
    errors = []

    @order_items_params.each do |item_params|
      product = Product.find(item_params[:product_id])
      quantity = item_params[:quantity].to_i

      if quantity <= 0
        errors << "商品 #{product.name} 數量必須大於 0"
        next
      end

      # 檢查商品是否存在且屬於當前商店的租戶
      unless product && product.tenant_id == @tenant.id
        errors << "商品不存在或無權限存取"
        next
      end

      # 檢查庫存
      unless product.in_stock?
        errors << "商品 #{product.name} 目前無庫存"
        next
      end

      # 檢查庫存數量是否足夠
      if product.stock_quantity < quantity
        errors << "商品 #{product.name} 庫存不足（目前庫存：#{product.stock_quantity}，需要：#{quantity}）"
      end
    end

    if errors.any?
      failure(errors, code: ErrorCodes::Order::INVENTORY_NOT_AVAILABLE)
    else
      success
    end
  end
end

