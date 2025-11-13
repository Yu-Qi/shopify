class AddBuyerProfileToOrders < ActiveRecord::Migration[7.1]
  def change
    add_reference :orders, :buyer_profile, foreign_key: true
  end
end

