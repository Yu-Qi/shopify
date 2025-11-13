# Product Model
# 代表一個商品
# 每個商店（Shop）可以擁有多個商品
# 使用 acts_as_tenant 來確保資料隔離

class Product < ApplicationRecord
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

  # 驗證：狀態必須是有效的值
  validates :status, inclusion: { in: %w[active inactive out_of_stock] }

  # 預設狀態為 active
  enum status: {
    active: 'active',          # 正常販售
    inactive: 'inactive',      # 停售
    out_of_stock: 'out_of_stock' # 缺貨
  }

  # 檢查商品是否有庫存
  def in_stock?
    stock_quantity > 0 && status == 'active'
  end

  # 減少庫存數量
  # 用於訂單建立時減少庫存
  def decrease_stock(quantity)
    # 使用原子操作確保併發安全
    update_column(:stock_quantity, stock_quantity - quantity)
    # 如果庫存為 0，自動更新狀態
    update(status: 'out_of_stock') if stock_quantity <= 0
  end
end

