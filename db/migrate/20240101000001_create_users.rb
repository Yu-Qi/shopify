# 建立 Users 資料表
# 用戶表：儲存系統中的用戶資訊（用戶 a, b, c 等）

class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :name, null: false, comment: '用戶名稱'
      t.string :email, null: false, comment: '用戶電子郵件'
      t.string :password_digest, null: false, comment: '加密後的密碼'

      t.timestamps
    end

    # 建立索引：email 必須唯一
    add_index :users, :email, unique: true
  end
end

