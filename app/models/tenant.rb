# Tenant Model
# 代表一個租戶（電商平台）
# 例如：用戶 a 建立的「電商平台 A」
# 使用 acts_as_tenant 來實現多租戶隔離

class Tenant < ApplicationRecord
  # 注意：Tenant 本身不是 tenant，它是租戶本身
  # 不需要設定 acts_as_tenant，因為它本身就是租戶

  # 關聯：一個租戶屬於一個用戶
  belongs_to :user

  # 關聯：一個租戶可以有多個商店
  # 例如：一個電商平台可能有多個分店或品牌
  has_many :shops, dependent: :destroy

  # 驗證：租戶名稱必須存在且唯一（在同一個用戶下）
  validates :name, presence: true, uniqueness: { scope: :user_id }

  # 驗證：domain 必須唯一（如果有的話）
  validates :domain, uniqueness: true, allow_nil: true

  # 生成唯一的 subdomain（用於多租戶識別）
  # 例如：tenant-a.shopify.com
  before_create :generate_subdomain

  private

  # 生成 subdomain
  # 使用租戶名稱的拼音或英文名稱作為 subdomain
  def generate_subdomain
    # 如果沒有手動設定 subdomain，則自動生成
    self.subdomain ||= name.parameterize
    # 確保 subdomain 的唯一性
    self.subdomain = "#{self.subdomain}-#{SecureRandom.hex(4)}" while Tenant.exists?(subdomain: self.subdomain)
  end
end

