# OrderItem Model
# 代表訂單中的一個項目（商品及其數量）
# 連接訂單（Order）和商品（Product）的多對多關聯

class OrderItem < ApplicationRecord
  # 設定這個 model 屬於某個 tenant
  # 確保不同租戶的訂單項目資料不會互相看到
  acts_as_tenant :tenant

  # 關聯：一個訂單項目屬於一個訂單
  belongs_to :order

  # 關聯：一個訂單項目屬於一個商品
  belongs_to :product

  # 驗證：數量必須大於 0
  validates :quantity, presence: true, numericality: { greater_than: 0 }

  # 驗證：價格必須大於 0
  validates :price, presence: true, numericality: { greater_than: 0 }

  # 計算小計（單項目的總金額）
  def subtotal
    price * quantity
  end

  # 在建立訂單項目時，自動設定價格為商品當時的價格
  # 這樣即使商品價格後來變動，訂單中的價格也不會改變
  before_validation :set_price_from_product, on: :create

  private

  # 從商品設定價格
  def set_price_from_product
    self.price = product.price if product && price.nil?
  end
end

