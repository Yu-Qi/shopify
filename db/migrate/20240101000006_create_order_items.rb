# 建立 OrderItems 資料表
# 訂單項目表：儲存訂單中的商品資訊（連接訂單和商品的多對多關聯）

class CreateOrderItems < ActiveRecord::Migration[7.1]
  def change
    create_table :order_items do |t|
      t.references :tenant, null: false, foreign_key: true, comment: '所屬租戶（用於多租戶隔離）'
      t.references :order, null: false, foreign_key: true, comment: '所屬訂單'
      t.references :product, null: false, foreign_key: true, comment: '所屬商品'
      t.integer :quantity, null: false, comment: '商品數量'
      t.decimal :price, precision: 10, scale: 2, null: false, comment: '商品價格（訂單建立時的價格）'

      t.timestamps
    end

    # 建立索引：用於查詢特定租戶的訂單項目（多租戶隔離）
    add_index :order_items, :tenant_id unless index_exists?(:order_items, :tenant_id)
    # 建立索引：用於查詢特定訂單的訂單項目
    add_index :order_items, :order_id unless index_exists?(:order_items, :order_id)
    # 建立索引：用於查詢特定商品的訂單項目
    add_index :order_items, :product_id unless index_exists?(:order_items, :product_id)
  end
end

