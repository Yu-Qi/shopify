# 建立 Products 資料表
# 商品表：儲存商品資訊（每個商店可以有多個商品）

class CreateProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :products do |t|
      t.references :tenant, null: false, foreign_key: true, comment: '所屬租戶（用於多租戶隔離）'
      t.references :shop, null: false, foreign_key: true, comment: '所屬商店'
      t.string :name, null: false, comment: '商品名稱'
      t.text :description, comment: '商品描述'
      t.decimal :price, precision: 10, scale: 2, null: false, comment: '商品價格'
      t.integer :stock_quantity, default: 0, null: false, comment: '庫存數量'
      t.string :sku, comment: '商品編號（SKU）'
      t.string :status, default: 'active', comment: '商品狀態（active, inactive, out_of_stock）'

      t.timestamps
    end

    # 建立索引：確保商品編號在同一個商店內唯一
    add_index :products, [:shop_id, :sku], unique: true unless index_exists?(:products, [:shop_id, :sku])
    # 建立索引：用於查詢特定狀態的商品
    add_index :products, :status unless index_exists?(:products, :status)
    # 建立索引：用於查詢特定租戶的商品（多租戶隔離）
    add_index :products, :tenant_id unless index_exists?(:products, :tenant_id)
  end
end

