class SellerProfile < ApplicationRecord
  belongs_to :user

  has_many :tenants, dependent: :destroy

  validates :user_id, uniqueness: true
end

