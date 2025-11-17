# Shopify 電商系統 - Ruby on Rails

這是一個基於 Ruby on Rails 的多租戶電商系統，支援多個用戶（用戶 a, b, c 等）透過系統建立自己的電商平台和訂單管理。
該項開發所花時間: 2天

## 如何執行（Getting Started）

### 使用 Docker 快速啟動

1. 建置服務映像檔：
   ```bash
   docker compose build
   ```
2. 啟動所有服務（Rails、PostgreSQL、Redis、Sidekiq）：
   ```bash
   docker compose up -d
   ```
3. 初次啟動會自動執行 `bundle exec rails db:prepare`，如需填充測試資料可額外執行：
   ```bash
   docker compose run --rm web bundle exec rails db:seed
   ```
4. 監看服務日誌（選擇性）：
   ```bash
   docker compose logs -f web
   ```
5. 停止並移除容器：
   ```bash
   docker compose down
   ```
- 更新程式碼
```bash
docker compose exec web bundle exec rails db:migrate
docker compose exec web bundle exec rails db:seed
docker compose restart web
```

應用程式預設會在 `http://localhost:3000` 提供服務，PostgreSQL 可透過 `localhost:5432` 連線。若需要進入 Rails 容器，可使用：
```bash
docker compose exec web bash
```

### 常用 Docker 指令

- `docker compose exec web bundle exec rails console`：開啟 Rails Console
- `docker compose exec web bundle exec rails db:migrate`：執行資料庫遷移
- `docker compose logs sidekiq`：即時查看 Sidekiq 背景任務日誌

## 專案架構

### 多租戶架構

本專案採用多租戶架構，使用 `acts_as_tenant` gem 來實現資料隔離：

- **User（用戶）**：系統中的用戶（用戶 a, b, c 等）
- **Tenant（租戶）**：每個用戶可以建立多個電商平台（租戶）
- **Shop（商店）**：每個租戶可以擁有多個商店
- **Product（商品）**：每個商店可以擁有多個商品
- **Order（訂單）**：每個商店可以擁有多個訂單

### 資料隔離

所有資料都透過 `tenant_id` 進行隔離，確保不同租戶的資料不會互相看到：
- 使用 `acts_as_tenant` 自動在所有查詢中加入 `tenant_id` 條件
- 確保資料安全性和穩定性


## 專案結構說明

```
shopify/
├── app/
│   ├── controllers/          # 控制器
│   │   ├── api/
│   │   │   └── v1/           # API v1 版本
│   │   │       ├── auth_controller.rb       # 認證相關
│   │   │       ├── users_controller.rb      # 用戶相關
│   │   │       ├── tenants_controller.rb    # 租戶相關
│   │   │       ├── shops_controller.rb      # 商店相關
│   │   │       ├── products_controller.rb   # 商品相關
│   │   │       └── orders_controller.rb     # 訂單相關
│   │   └── application_controller.rb        # 基礎控制器
│   ├── models/               # 資料模型
│   │   ├── user.rb           # 用戶模型
│   │   ├── tenant.rb         # 租戶模型
│   │   ├── shop.rb           # 商店模型
│   │   ├── product.rb        # 商品模型
│   │   ├── order.rb          # 訂單模型
│   │   └── order_item.rb     # 訂單項目模型
│   └── services/             # Service Objects（業務邏輯）
│       ├── application_service.rb
│       ├── tenant_service.rb
│       ├── shop_service.rb
│       ├── product_service.rb
│       ├── order_service.rb
│       ├── order_cancellation_service.rb
│       └── order_completion_service.rb
├── config/
│   ├── application.rb        # 應用程式設定
│   ├── routes.rb             # 路由設定
│   ├── database.yml          # 資料庫設定
│   ├── environments/         # 環境設定
│   └── initializers/         # 初始化設定
│       ├── cors.rb           # 跨域設定
│       ├── acts_as_tenant.rb # 多租戶設定
│       └── sidekiq.rb        # Sidekiq 設定
├── db/
│   ├── migrate/              # 資料庫遷移檔案
│   └── schema.rb             # 資料庫結構
├── Gemfile                   # 套件依賴
└── README.md                 # 說明文件
```

## API 端點說明

### 認證相關

- `POST /api/v1/auth/register` - 用戶註冊
- `POST /api/v1/auth/login` - 用戶登入
- `POST /api/v1/auth/logout` - 用戶登出

### 用戶相關

- `GET /api/v1/me` - 取得當前用戶資訊
- `GET /api/v1/my-tenants` - 取得當前用戶的所有租戶

### 店家 / 買家資料

- `GET /api/v1/seller_profile` - 檢視當前使用者的店家資料
- `POST /api/v1/seller_profile` - 建立店家資料
- `DELETE /api/v1/seller_profile` - 刪除店家資料
- `GET /api/v1/buyer_profile` - 檢視當前使用者的買家資料
- `POST /api/v1/buyer_profile` - 建立買家資料
- `DELETE /api/v1/buyer_profile` - 刪除買家資料

### 租戶相關

- `POST /api/v1/tenants` - 建立新租戶
- `GET /api/v1/tenants/:id` - 取得單一租戶
- `PATCH /api/v1/tenants/:id` - 更新租戶
- `DELETE /api/v1/tenants/:id` - 刪除租戶
- `GET /api/v1/my-tenants` - 取得當前用戶的所有租戶

### 商店相關

- `GET /api/v1/shops` - 取得租戶的所有商店（依據 token 判斷租戶）
- `POST /api/v1/shops` - 建立新商店
- `GET /api/v1/shops/:id` - 取得單一商店
- `PATCH /api/v1/shops/:id` - 更新商店
- `DELETE /api/v1/shops/:id` - 刪除商店

### 商品相關

- `GET /api/v1/shops/:shop_id/products` - 取得商店的所有商品
- `POST /api/v1/shops/:shop_id/products` - 建立新商品
- `GET /api/v1/shops/:shop_id/products/:id` - 取得單一商品
- `PATCH /api/v1/shops/:shop_id/products/:id` - 更新商品
- `DELETE /api/v1/shops/:shop_id/products/:id` - 刪除商品

### 訂單相關

- `GET /api/v1/shops/:shop_id/orders` - 取得商店的所有訂單
- `POST /api/v1/shops/:shop_id/orders` - 建立新訂單
- `GET /api/v1/shops/:shop_id/orders/:id` - 取得單一訂單
- `PATCH /api/v1/shops/:shop_id/orders/:id` - 更新訂單
- `PATCH /api/v1/shops/:shop_id/orders/:id/cancel` - 取消訂單
- `PATCH /api/v1/shops/:shop_id/orders/:id/complete` - 完成訂單

### 付款相關

- `POST /api/v1/orders/:order_id/payments` - 建立訂單付款

### 健康檢查

- `GET /health` - 系統健康檢查

## 使用範例

### 1. 註冊用戶

```bash
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "name": "用戶 A",
      "email": "user_a@example.com",
      "password": "password123",
      "password_confirmation": "password123"
    }
  }'
```

### 2. 登入

```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "user_a@example.com",
      "password": "password123"
    }
  }'
```

回應會包含 `token`，後續請求需要在 Header 中加入：
```
Authorization: Bearer <token>
```

### 3. 建立店家資料

在建立租戶之前，需要先建立店家資料（seller_profile）：

```bash
curl -X POST http://localhost:3000/api/v1/seller_profile \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "seller_profile": {
      "display_name": "我的商店"
    }
  }'
```

### 4. 建立租戶（電商平台）

```bash
curl -X POST http://localhost:3000/api/v1/tenants \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "tenant": {
      "name": "電商平台 A",
      "description": "這是用戶 A 的電商平台"
    }
  }'
```

### 5. 建立商店

```bash
curl -X POST http://localhost:3000/api/v1/shops \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "shop": {
      "name": "主商店",
      "description": "這是主商店"
    }
  }'
```

### 6. 建立商品

```bash
curl -X POST http://localhost:3000/api/v1/shops/1/products \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "product": {
      "name": "商品 A",
      "description": "這是商品 A",
      "price": 100.00,
      "stock_quantity": 100,
      "sku": "PROD-A-001"
    }
  }'
```

### 7. 建立買家資料（選用）

如果需要以買家身份下單，可以建立買家資料：

```bash
curl -X POST http://localhost:3000/api/v1/buyer_profile \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "buyer_profile": {
      "display_name": "用戶 A 的買家"
    }
  }'
```

### 8. 取得當前用戶資訊 / 租戶列表

```bash
# 取得當前用戶資訊
curl -X GET http://localhost:3000/api/v1/me \
  -H "Authorization: Bearer <token>"

# 取得當前用戶擁有的租戶列表
curl -X GET http://localhost:3000/api/v1/my-tenants \
  -H "Authorization: Bearer <token>"
```

### 8. 建立訂單

```bash
curl -X POST http://localhost:3000/api/v1/shops/1/orders \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "order": {
      "customer_name": "客戶姓名",
      "customer_email": "customer@example.com",
      "shipping_address": "配送地址",
      "order_items": [
        {
          "product_id": 1,
          "quantity": 2
        }
      ]
    }
  }'
```

### 9. 訂單付款

```bash
curl -X POST http://localhost:3000/api/v1/orders/1/payments \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <buyer_token>" \
  -d '{
    "payment": {
      "amount": "200.00",
      "payment_method": "credit_card",
      "transaction_reference": "TXN-20250101-0001",
      "metadata": {
        "gateway": "TestPay"
      }
    }
  }'
```

### 10. 取消 / 完成訂單

```bash
# 取消訂單
curl -X PATCH http://localhost:3000/api/v1/shops/1/orders/1/cancel \
  -H "Authorization: Bearer <token>"

# 完成訂單
curl -X PATCH http://localhost:3000/api/v1/shops/1/orders/1/complete \
  -H "Authorization: Bearer <token>"
```

## 架構設計說明

### Service Objects 模式

本專案使用 Service Objects 模式來處理複雜的業務邏輯：

- **優點**：
  - 將業務邏輯從 Controller 抽離，提高程式碼可重用性
  - 方便單元測試
  - 避免 Controller 過於複雜
  - 在多租戶場景下，可以集中處理租戶隔離邏輯

- **使用範例**：
  - `OrderService`：處理訂單建立邏輯（庫存檢查、扣減等）
  - `OrderCancellationService`：處理訂單取消邏輯（庫存回退等）
  - `OrderCompletionService`：處理訂單完成邏輯

### 多租戶隔離

- 使用 `acts_as_tenant` gem 自動在所有查詢中加入 `tenant_id` 條件
- 確保不同租戶的資料完全隔離
- 透過 `ActsAsTenant.current_tenant` 設定當前租戶
- 在 Controller 中透過 `set_current_tenant` 方法設定租戶

### 資料庫交易

複雜的業務邏輯（如訂單建立、取消）都使用 `ActiveRecord::Base.transaction` 確保資料一致性：
- 訂單建立時，庫存扣減和訂單建立必須全部成功，否則全部失敗
- 訂單取消時，庫存回退和訂單狀態更新必須全部成功，否則全部失敗

### 錯誤處理

- 在 Controller 中使用 `rescue_from` 統一處理錯誤
- 在 Service Objects 中使用 `begin/rescue` 處理錯誤並回傳統一的錯誤格式


## 常見問題

### Q: 如何確保多租戶資料隔離？

A: 使用 `acts_as_tenant` gem，所有查詢都會自動加入 `tenant_id` 條件。在 Controller 中透過 `set_current_tenant` 設定當前租戶。

### Q: 訂單建立時如何確保庫存正確扣減？

A: 使用 `ActiveRecord::Base.transaction` 確保訂單建立和庫存扣減的原子性。如果其中任何一步失敗，整個交易會回滾。

### Q: 如何處理併發訂單？

A: 使用資料庫交易和原子操作（如 `update_column`）來確保併發安全。並且在庫存操作時使用鎖定（如 `lock!`）來確保併發安全。



## 開發工具

### 自動生成 Model 註解

```bash
# 安裝 annotate gem 後，執行以下指令自動生成註解
bundle exec annotate
```

### 執行測試

```bash
# 執行所有測試
bundle exec rspec

# 執行特定測試
bundle exec rspec spec/models/user_spec.rb
```

### 資料庫操作

```bash
# 建立資料庫
rails db:create

# 執行遷移
rails db:migrate

# 回滾遷移
rails db:rollback

# 重置資料庫
rails db:reset

# 查看資料庫狀態
rails db:migrate:status
```

## 部署注意事項

### 生產環境設定

1. 設定環境變數：
   - `SECRET_KEY_BASE`
   - `DATABASE_URL`
   - `REDIS_URL`

2. 設定資料庫連線池：
   在 `config/database.yml` 中調整 `pool` 設定

3. 設定 CORS：
   在 `config/initializers/cors.rb` 中設定允許的來源域名

4. 設定 Sidekiq：
   確保 Redis 服務正常運行
