# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2024_11_13_001400) do
  create_table "buyer_profiles", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "display_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_buyer_profiles_on_user_id", unique: true
  end

  create_table "order_items", force: :cascade do |t|
    t.integer "tenant_id", null: false
    t.integer "order_id", null: false
    t.integer "product_id", null: false
    t.integer "quantity", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
    t.index ["tenant_id"], name: "index_order_items_on_tenant_id"
  end

  create_table "orders", force: :cascade do |t|
    t.integer "tenant_id", null: false
    t.integer "shop_id", null: false
    t.string "order_number", null: false
    t.string "customer_name", null: false
    t.string "customer_email", null: false
    t.text "shipping_address", null: false
    t.decimal "total_amount", precision: 10, scale: 2, null: false
    t.string "status", default: "pending"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "buyer_profile_id"
    t.index ["buyer_profile_id"], name: "index_orders_on_buyer_profile_id"
    t.index ["order_number"], name: "index_orders_on_order_number", unique: true
    t.index ["shop_id"], name: "index_orders_on_shop_id"
    t.index ["status"], name: "index_orders_on_status"
    t.index ["tenant_id"], name: "index_orders_on_tenant_id"
  end

  create_table "payments", force: :cascade do |t|
    t.integer "order_id", null: false
    t.integer "buyer_profile_id", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.string "status", default: "pending", null: false
    t.string "payment_method"
    t.string "transaction_reference"
    t.json "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["buyer_profile_id"], name: "index_payments_on_buyer_profile_id"
    t.index ["order_id"], name: "index_payments_on_order_id", unique: true
    t.index ["status"], name: "index_payments_on_status"
  end

  create_table "products", force: :cascade do |t|
    t.integer "tenant_id", null: false
    t.integer "shop_id", null: false
    t.string "name", null: false
    t.text "description"
    t.decimal "price", precision: 10, scale: 2, null: false
    t.integer "stock_quantity", default: 0, null: false
    t.string "sku"
    t.string "status", default: "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id", "sku"], name: "index_products_on_shop_id_and_sku", unique: true
    t.index ["shop_id"], name: "index_products_on_shop_id"
    t.index ["status"], name: "index_products_on_status"
    t.index ["tenant_id"], name: "index_products_on_tenant_id"
  end

  create_table "seller_profiles", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "display_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_seller_profiles_on_user_id", unique: true
  end

  create_table "shops", force: :cascade do |t|
    t.integer "tenant_id", null: false
    t.string "name", null: false
    t.text "description"
    t.string "status", default: "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_shops_on_status"
    t.index ["tenant_id", "name"], name: "index_shops_on_tenant_id_and_name", unique: true
    t.index ["tenant_id"], name: "index_shops_on_tenant_id"
  end

  create_table "tenants", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "subdomain"
    t.string "domain"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "seller_profile_id", null: false
    t.index ["domain"], name: "index_tenants_on_domain", unique: true
    t.index ["name"], name: "index_tenants_on_user_id_and_name", unique: true
    t.index ["seller_profile_id"], name: "index_tenants_on_seller_profile_id"
    t.index ["subdomain"], name: "index_tenants_on_subdomain", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "buyer_profiles", "users"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "order_items", "tenants"
  add_foreign_key "orders", "buyer_profiles"
  add_foreign_key "orders", "shops"
  add_foreign_key "orders", "tenants"
  add_foreign_key "payments", "buyer_profiles"
  add_foreign_key "payments", "orders"
  add_foreign_key "products", "shops"
  add_foreign_key "products", "tenants"
  add_foreign_key "seller_profiles", "users"
  add_foreign_key "shops", "tenants"
  add_foreign_key "tenants", "seller_profiles"
end
