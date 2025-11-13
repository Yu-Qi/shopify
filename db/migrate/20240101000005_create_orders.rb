# 建立 Orders 資料表
# 訂單表：儲存訂單資訊（每個商店可以有多個訂單）

class CreateOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :orders do |t|
      t.references :tenant, null: false, foreign_key: true, comment: '所屬租戶（用於多租戶隔離）'
      t.references :shop, null: false, foreign_key: true, comment: '所屬商店'
      t.string :order_number, null: false, comment: '訂單編號'
      t.string :customer_name, null: false, comment: '客戶姓名'
      t.string :customer_email, null: false, comment: '客戶電子郵件'
      t.text :shipping_address, null: false, comment: '配送地址'
      t.decimal :total_amount, precision: 10, scale: 2, null: false, comment: '訂單總金額'
      t.string :status, default: 'pending', comment: '訂單狀態（pending, processing, shipped, completed, cancelled）'

      t.timestamps
    end

    # 建立索引：訂單編號必須唯一
    add_index :orders, :order_number, unique: true unless index_exists?(:orders, :order_number)
    # 建立索引：用於查詢特定狀態的訂單
    add_index :orders, :status unless index_exists?(:orders, :status)
    # 建立索引：用於查詢特定租戶的訂單（多租戶隔離）
    add_index :orders, :tenant_id unless index_exists?(:orders, :tenant_id)
    # 建立索引：用於查詢特定商店的訂單
    add_index :orders, :shop_id unless index_exists?(:orders, :shop_id)
  end
end

