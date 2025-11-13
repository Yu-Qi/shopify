class Payment < ApplicationRecord
  STATUSES = {
    pending: 'pending',
    completed: 'completed',
    failed: 'failed'
  }.freeze

  belongs_to :order
  belongs_to :buyer_profile

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: STATUSES.values }
  validates :order_id, uniqueness: true

  enum status: STATUSES
end

