class CreatePayments < ActiveRecord::Migration[7.1]
  def change
    create_table :payments do |t|
      t.references :order, null: false, foreign_key: true, index: { unique: true }
      t.references :buyer_profile, null: false, foreign_key: true
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.string :status, null: false, default: 'pending'
      t.string :payment_method
      t.string :transaction_reference

      metadata_column_type = if connection.adapter_name.downcase.include?("sqlite")
        :json
      else
        :jsonb
      end
      t.send(metadata_column_type, :metadata, default: {})

      t.timestamps
    end

    add_index :payments, :status unless index_exists?(:payments, :status)
  end
end

