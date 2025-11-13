class BuyerProfile < ApplicationRecord
  belongs_to :user

  has_many :payments, dependent: :destroy

  validates :user_id, uniqueness: true
end

