# Product Model
# 代表一個商品
# 每個商店（Shop）可以擁有多個商品
# 使用 acts_as_tenant 來確保資料隔離

class Product < ApplicationRecord
  class StockAdjustmentError < StandardError; end
  class InvalidStockQuantityError < StockAdjustmentError; end
  class InsufficientStockError < StockAdjustmentError; end
  # 設定這個 model 屬於某個 tenant
  # 確保不同租戶的商品資料不會互相看到
  acts_as_tenant :tenant

  # 關聯：一個商品屬於一個商店
  belongs_to :shop

  # 關聯：一個商品可以出現在多個訂單項目中
  # 使用 through: :order_items 來關聯到訂單
  has_many :order_items, dependent: :destroy
  has_many :orders, through: :order_items

  # 驗證：商品名稱必須存在
  validates :name, presence: true

  # 驗證：商品編號在商店內必須唯一
  validates :sku, uniqueness: { scope: :shop_id }, allow_nil: true

  # 驗證：價格必須大於 0
  validates :price, presence: true, numericality: { greater_than: 0 }

  # 驗證：庫存數量不能為負數
  validates :stock_quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }

  STATUSES = {
    active: 'active',            # 正常販售
    inactive: 'inactive',        # 停售
    out_of_stock: 'out_of_stock' # 缺貨
  }.freeze

  STATUS_ACTIVE       = STATUSES[:active]
  STATUS_INACTIVE     = STATUSES[:inactive]
  STATUS_OUT_OF_STOCK = STATUSES[:out_of_stock]

  # 驗證：狀態必須是有效的值
  validates :status, inclusion: { in: STATUSES.values }

  # 預設狀態為 active
  enum status: STATUSES

  # 檢查商品是否有庫存
  def in_stock?
    stock_quantity.positive? && status == STATUS_ACTIVE
  end

  # 減少庫存數量（原子操作）
  def decrease_stock!(quantity)
    qty = quantity.to_i
    raise InvalidStockQuantityError, "數量必須為正整數" unless qty.positive?
    adjust_stock!(-qty)
  end

  # 增加庫存數量（原子操作）
  def increase_stock!(quantity)
    qty = quantity.to_i
    raise InvalidStockQuantityError, "數量必須為正整數" unless qty.positive?
    adjust_stock!(qty)
  end

  private

  def adjust_stock!(delta)
    quantity = delta.to_i

    transaction do
      lock! # 針對同一筆商品進行鎖定，避免併發問題

      new_quantity = stock_quantity + quantity
      if quantity.negative? && new_quantity.negative?
        raise InsufficientStockError, "商品 #{name} 庫存不足（目前庫存：#{stock_quantity}，需要：#{quantity.abs}）"
      end

      attrs = { stock_quantity: [new_quantity, 0].max }

      if attrs[:stock_quantity].zero?
        attrs[:status] = STATUS_OUT_OF_STOCK
      elsif status == STATUS_OUT_OF_STOCK
        attrs[:status] = STATUS_ACTIVE
      end

      update!(attrs)
    end
  end
end

