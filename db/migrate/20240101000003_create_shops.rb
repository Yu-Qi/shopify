# 建立 Shops 資料表
# 商店表：儲存商店資訊（每個租戶可以有多個商店）

class CreateShops < ActiveRecord::Migration[7.1]
  def change
    create_table :shops do |t|
      t.references :tenant, null: false, foreign_key: true, comment: '所屬租戶'
      t.string :name, null: false, comment: '商店名稱'
      t.text :description, comment: '商店描述'
      t.string :status, default: 'active', comment: '商店狀態（active, inactive, suspended）'

      t.timestamps
    end

    # 建立索引：確保商店名稱在同一個租戶下唯一
    add_index :shops, [:tenant_id, :name], unique: true
    # 建立索引：用於查詢特定狀態的商店
    add_index :shops, :status
  end
end

