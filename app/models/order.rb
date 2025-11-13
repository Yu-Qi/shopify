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
  belongs_to :buyer_profile, optional: true

  # 關聯：一個訂單可以有多個訂單項目
  has_many :order_items, dependent: :destroy

  # 關聯：一個訂單可以有多個商品（透過 order_items）
  has_many :products, through: :order_items
  has_one :payment, dependent: :destroy

  # 驗證：訂單編號必須唯一
  validates :order_number, presence: true, uniqueness: true

  STATUSES = {
    pending: 'pending',         # 待處理
    processing: 'processing',   # 處理中
    shipped: 'shipped',         # 已出貨
    completed: 'completed',     # 已完成
    cancelled: 'cancelled'      # 已取消
  }.freeze

  STATUS_PENDING    = STATUSES[:pending]
  STATUS_PROCESSING = STATUSES[:processing]
  STATUS_SHIPPED    = STATUSES[:shipped]
  STATUS_COMPLETED  = STATUSES[:completed]
  STATUS_CANCELLED  = STATUSES[:cancelled]

  # 驗證：訂單狀態必須是有效的值
  validates :status, inclusion: { in: STATUSES.values }

  # 驗證：總金額必須大於 0
  validates :total_amount, presence: true, numericality: { greater_than: 0 }

  # 預設狀態為 pending
  enum status: STATUSES

  # 生成唯一的訂單編號
  # 格式：ORD-YYYYMMDD-XXXXXX
  before_validation :generate_order_number, on: :create

  # 計算訂單總金額
  # 從所有訂單項目的總和計算
  before_validation :calculate_total_amount

  # 訂單狀態轉換規則
  # 定義哪些狀態可以轉換到哪些狀態
  def can_transition_to?(new_status)
    target_status = normalize_status(new_status)
    return false unless target_status

    case status
    when STATUS_PENDING
      [STATUS_PROCESSING, STATUS_CANCELLED].include?(target_status)
    when STATUS_PROCESSING
      [STATUS_SHIPPED, STATUS_CANCELLED].include?(target_status)
    when STATUS_SHIPPED
      [STATUS_COMPLETED].include?(target_status)
    when STATUS_COMPLETED, STATUS_CANCELLED
      false  # 已完成或已取消的訂單不能轉換狀態
    else
      false
    end
  end

  # 取消訂單
  # 需要處理庫存回退等邏輯
  def cancel!
    return false unless can_transition_to?(STATUS_CANCELLED)

    # 使用 transaction 確保資料一致性
    transaction do
      # 回退庫存
      order_items.includes(:product).each do |item|
        product = item.product
        product.increase_stock!(item.quantity)
      end
      # 更新訂單狀態
      update!(status: STATUS_CANCELLED)
    end

    true
  end

  # 完成訂單
  def complete!
    return false unless can_transition_to?(STATUS_COMPLETED)
    update!(status: STATUS_COMPLETED)
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

  def normalize_status(value)
    return value if STATUSES.values.include?(value)
    return STATUSES[value.to_sym] if value.is_a?(Symbol) && STATUSES.key?(value.to_sym)

    nil
  end
end

