# User Model
# 代表系統中的用戶（用戶 a, b, c 等）
# 一個用戶可以擁有多個租戶（Tenant），每個租戶代表一個電商平台

class User < ApplicationRecord
  # 使用 bcrypt 加密密碼
  has_secure_password

  # 關聯：一個用戶可以擁有店家或買家資料
  has_one :seller_profile, dependent: :destroy
  has_one :buyer_profile, dependent: :destroy
  has_many :tenants, through: :seller_profile

  # 驗證：email 必須存在且唯一
  validates :email, presence: true, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }

  # 驗證：名稱必須存在
  validates :name, presence: true

  def seller?
    seller_profile.present?
  end

  def buyer?
    buyer_profile.present?
  end

  # 生成 JWT token 的方法
  # 用於 API 認證
  def generate_token
    # 使用 JWT 生成 token，包含用戶 ID 和過期時間
    payload = {
      user_id: id,
      exp: 24.hours.from_now.to_i  # 24 小時後過期
    }
    JWT.encode(payload, Rails.application.credentials.secret_key_base, 'HS256')
  end

  # 從 token 解析用戶
  # 靜態方法，用於從請求中的 token 找到對應用戶
  def self.from_token(token)
    decoded = JWT.decode(token, Rails.application.credentials.secret_key_base, true, { algorithm: 'HS256' })
    find(decoded[0]['user_id'])
  rescue JWT::DecodeError, ActiveRecord::RecordNotFound
    nil
  end
end

