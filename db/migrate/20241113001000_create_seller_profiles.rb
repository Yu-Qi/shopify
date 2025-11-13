class CreateSellerProfiles < ActiveRecord::Migration[7.1]
  def change
    create_table :seller_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :display_name
      t.timestamps
    end
  end
end

