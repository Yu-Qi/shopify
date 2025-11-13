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

ActiveRecord::Schema[7.1].define(version: 20240101000006) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "order_items", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "order_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
    t.index ["tenant_id"], name: "index_order_items_on_tenant_id"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "shop_id", null: false
    t.string "order_number", null: false
    t.string "customer_name", null: false
    t.string "customer_email", null: false
    t.text "shipping_address", null: false
    t.decimal "total_amount", precision: 10, scale: 2, null: false
    t.string "status", default: "pending"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_number"], name: "index_orders_on_order_number", unique: true
    t.index ["shop_id"], name: "index_orders_on_shop_id"
    t.index ["status"], name: "index_orders_on_status"
    t.index ["tenant_id"], name: "index_orders_on_tenant_id"
  end

  create_table "products", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "shop_id", null: false
    t.string "name", null: false
    t.text "description"
    t.decimal "price", precision: 10, scale: 2, null: false
    t.integer "stock_quantity", default: 0, null: false
    t.string "sku"
    t.string "status", default: "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id", "sku"], name: "index_products_on_shop_id_and_sku", unique: true
    t.index ["status"], name: "index_products_on_status"
    t.index ["tenant_id"], name: "index_products_on_tenant_id"
  end

  create_table "shops", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.string "name", null: false
    t.text "description"
    t.string "status", default: "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_shops_on_status"
    t.index ["tenant_id", "name"], name: "index_shops_on_tenant_id_and_name", unique: true
  end

  create_table "tenants", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.text "description"
    t.string "subdomain"
    t.string "domain"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["domain"], name: "index_tenants_on_domain", unique: true
    t.index ["subdomain"], name: "index_tenants_on_subdomain", unique: true
    t.index ["user_id", "name"], name: "index_tenants_on_user_id_and_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "order_items", "tenants"
  add_foreign_key "orders", "shops"
  add_foreign_key "orders", "tenants"
  add_foreign_key "products", "shops"
  add_foreign_key "products", "tenants"
  add_foreign_key "shops", "tenants"
  add_foreign_key "tenants", "users"
end

