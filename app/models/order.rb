# Order Model
# 代表一個訂單
# 每個商店（Shop）可以擁有多個訂單
# 使用 acts_as_tenant 來確保資料隔離

class Order < ApplicationRecord
  # 設定這個 model 屬於某個 tenant
  # 確保不同租戶的訂單資料不會互相看到
  acts_as_tenant :tenant

  # 關聯：一個訂單屬於一個商店
  belongs_to :shop

  # 關聯：一個訂單可以有多個訂單項目
  has_many :order_items, dependent: :destroy

  # 關聯：一個訂單可以有多個商品（透過 order_items）
  has_many :products, through: :order_items

  # 驗證：訂單編號必須唯一
  validates :order_number, presence: true, uniqueness: true

  # 驗證：訂單狀態必須是有效的值
  validates :status, inclusion: { in: %w[pending processing shipped completed cancelled] }

  # 驗證：總金額必須大於 0
  validates :total_amount, presence: true, numericality: { greater_than: 0 }

  # 預設狀態為 pending
  enum status: {
    pending: 'pending',         # 待處理
    processing: 'processing',   # 處理中
    shipped: 'shipped',        # 已出貨
    completed: 'completed',    # 已完成
    cancelled: 'cancelled'      # 已取消
  }

  # 生成唯一的訂單編號
  # 格式：ORD-YYYYMMDD-XXXXXX
  before_validation :generate_order_number, on: :create

  # 計算訂單總金額
  # 從所有訂單項目的總和計算
  before_save :calculate_total_amount

  # 訂單狀態轉換規則
  # 定義哪些狀態可以轉換到哪些狀態
  def can_transition_to?(new_status)
    case status
    when 'pending'
      %w[processing cancelled].include?(new_status)
    when 'processing'
      %w[shipped cancelled].include?(new_status)
    when 'shipped'
      %w[completed].include?(new_status)
    when 'completed', 'cancelled'
      false  # 已完成或已取消的訂單不能轉換狀態
    else
      false
    end
  end

  # 取消訂單
  # 需要處理庫存回退等邏輯
  def cancel!
    return false unless can_transition_to?('cancelled')

    # 使用 transaction 確保資料一致性
    transaction do
      # 回退庫存
      order_items.each do |item|
        item.product.increment!(:stock_quantity, item.quantity)
        item.product.update(status: 'active') if item.product.out_of_stock?
      end
      # 更新訂單狀態
      update!(status: 'cancelled')
    end
  end

  # 完成訂單
  def complete!
    return false unless can_transition_to?('completed')
    update!(status: 'completed')
  end

  private

  # 生成訂單編號
  def generate_order_number
    return if order_number.present?
    # 格式：ORD-YYYYMMDD-XXXXXX
    date_part = Date.today.strftime('%Y%m%d')
    random_part = SecureRandom.hex(3).upcase
    self.order_number = "ORD-#{date_part}-#{random_part}"
  end

  # 計算總金額
  def calculate_total_amount
    self.total_amount = order_items.sum { |item| item.price * item.quantity }
  end
end

