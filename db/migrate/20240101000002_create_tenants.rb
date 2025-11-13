# 建立 Tenants 資料表
# 租戶表：儲存電商平台資訊（每個用戶可以建立多個電商平台）

class CreateTenants < ActiveRecord::Migration[7.1]
  def change
    create_table :tenants do |t|
      t.references :user, null: false, foreign_key: true, comment: '所屬用戶'
      t.string :name, null: false, comment: '租戶名稱（電商平台名稱）'
      t.text :description, comment: '租戶描述'
      t.string :subdomain, comment: '子域名（用於多租戶識別）'
      t.string :domain, comment: '自訂域名'

      t.timestamps
    end

    # 建立索引：確保租戶名稱在同一個用戶下唯一
    add_index :tenants, [:user_id, :name], unique: true
    # 建立索引：subdomain 必須唯一
    add_index :tenants, :subdomain, unique: true
    # 建立索引：domain 必須唯一（如果有的話）
    add_index :tenants, :domain, unique: true
  end
end

