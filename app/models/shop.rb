# Shop Model
# 代表一個商店
# 每個租戶（Tenant）可以擁有多個商店
# 使用 acts_as_tenant 來確保資料隔離（不同租戶的商店資料不會互相看到）

class Shop < ApplicationRecord
  # 設定這個 model 屬於某個 tenant
  # 這樣會自動在所有查詢中加入 tenant_id 條件，確保資料隔離
  acts_as_tenant :tenant

  # 關聯：一個商店屬於一個租戶
  belongs_to :tenant

  # 關聯：一個商店可以有多個商品
  has_many :products, dependent: :destroy

  # 關聯：一個商店可以有多個訂單
  has_many :orders, dependent: :destroy

  # 驗證：商店名稱必須存在
  validates :name, presence: true

  # 驗證：商店名稱在同一個租戶下必須唯一
  validates :name, uniqueness: { scope: :tenant_id }

  STATUSES = {
    active: 'active',      # 正常營運
    inactive: 'inactive',  # 未啟用
    suspended: 'suspended' # 暫停營運
  }.freeze

  STATUS_ACTIVE    = STATUSES[:active]
  STATUS_INACTIVE  = STATUSES[:inactive]
  STATUS_SUSPENDED = STATUSES[:suspended]

  # 驗證：狀態必須是有效的值
  validates :status, inclusion: { in: STATUSES.values }

  # 預設狀態為 active
  enum status: STATUSES

  # 檢查商店是否可以接收訂單
  def can_receive_orders?
    status == STATUS_ACTIVE
  end
end

