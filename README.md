# Shopify 電商系統 - Ruby on Rails

這是一個基於 Ruby on Rails 的多租戶電商系統，支援多個用戶（用戶 a, b, c 等）透過系統建立自己的電商平台和訂單管理。

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

## 環境需求

- Ruby 3.3.4（或 3.2.2+）
- PostgreSQL 12+
- Redis 6+（用於 Sidekiq 背景任務）
- Bundler

## 安裝步驟

### 1. 安裝 Ruby 和 PostgreSQL

#### macOS（使用 Homebrew）：
```bash
# 安裝 Ruby（建議使用 rbenv 或 rvm）
brew install rbenv
rbenv install 3.3.4
rbenv global 3.3.4

# 安裝 PostgreSQL
brew install postgresql@14
brew services start postgresql@14

# 安裝 Redis
brew install redis
brew services start redis
```

#### Linux（Ubuntu/Debian）：
```bash
# 安裝 Ruby（建議使用 rbenv）
sudo apt update
sudo apt install -y build-essential libssl-dev libreadline-dev zlib1g-dev
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash
rbenv install 3.3.4
rbenv global 3.3.4

# 安裝 PostgreSQL
sudo apt install -y postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql

# 安裝 Redis
sudo apt install -y redis-server
sudo systemctl start redis-server
sudo systemctl enable redis-server
```

### 2. 建立專案資料夾結構

專案已經建立好所有必要的資料夾結構，如果需要在新的位置建立，請執行：

```bash
# 建立專案資料夾
mkdir -p shopify
cd shopify

# 如果需要重新初始化 Rails 專案（不建議，因為已經有完整結構）
# rails new . --database=postgresql --api
```

### 3. 安裝套件

```bash
# 安裝 Bundler（如果還沒安裝）
gem install bundler

# 安裝所有 gem 套件
bundle install
```

### 4. 設定資料庫

```bash
# 建立 PostgreSQL 資料庫用戶（如果還沒建立）
# macOS/Linux:
sudo -u postgres createuser -s $USER
# 或手動建立：
# sudo -u postgres psql
# CREATE USER your_username WITH PASSWORD 'your_password';
# ALTER USER your_username CREATEDB;

# 設定環境變數（可選）
cp .env.example .env
# 編輯 .env 檔案，填入資料庫設定

# 建立資料庫
rails db:create

# 執行資料庫遷移
rails db:migrate

# 如果需要填充測試資料（可選）
rails db:seed
```

### 5. 設定 Rails 密鑰

```bash
# 生成 secret key base
rails secret

# 設定環境變數
export SECRET_KEY_BASE=your-generated-secret-key-base

# 或編輯 .env 檔案，加入：
# SECRET_KEY_BASE=your-generated-secret-key-base
```

### 6. 啟動服務

#### 啟動 Rails 伺服器：

```bash
# 開發環境
rails server
# 或
rails s

# 預設會在 http://localhost:3000 啟動
```

#### 啟動 Sidekiq（背景任務處理）：

```bash
# 在另一個終端視窗執行
bundle exec sidekiq
```

#### 啟動 Redis（如果還沒啟動）：

```bash
# macOS（使用 Homebrew）
brew services start redis

# Linux
sudo systemctl start redis-server
```

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

### 租戶相關

- `GET /api/v1/tenants` - 取得所有租戶（當前用戶的）
- `POST /api/v1/tenants` - 建立新租戶
- `GET /api/v1/tenants/:id` - 取得單一租戶
- `PATCH /api/v1/tenants/:id` - 更新租戶
- `DELETE /api/v1/tenants/:id` - 刪除租戶

### 商店相關

- `GET /api/v1/tenants/:tenant_id/shops` - 取得租戶的所有商店
- `POST /api/v1/tenants/:tenant_id/shops` - 建立新商店
- `GET /api/v1/tenants/:tenant_id/shops/:id` - 取得單一商店
- `PATCH /api/v1/tenants/:tenant_id/shops/:id` - 更新商店
- `DELETE /api/v1/tenants/:tenant_id/shops/:id` - 刪除商店

### 商品相關

- `GET /api/v1/tenants/:tenant_id/shops/:shop_id/products` - 取得商店的所有商品
- `POST /api/v1/tenants/:tenant_id/shops/:shop_id/products` - 建立新商品
- `GET /api/v1/tenants/:tenant_id/shops/:shop_id/products/:id` - 取得單一商品
- `PATCH /api/v1/tenants/:tenant_id/shops/:shop_id/products/:id` - 更新商品
- `DELETE /api/v1/tenants/:tenant_id/shops/:shop_id/products/:id` - 刪除商品

### 訂單相關

- `GET /api/v1/tenants/:tenant_id/shops/:shop_id/orders` - 取得商店的所有訂單
- `POST /api/v1/tenants/:tenant_id/shops/:shop_id/orders` - 建立新訂單
- `GET /api/v1/tenants/:tenant_id/shops/:shop_id/orders/:id` - 取得單一訂單
- `PATCH /api/v1/tenants/:tenant_id/shops/:shop_id/orders/:id` - 更新訂單
- `PATCH /api/v1/tenants/:tenant_id/shops/:shop_id/orders/:id/cancel` - 取消訂單
- `PATCH /api/v1/tenants/:tenant_id/shops/:shop_id/orders/:id/complete` - 完成訂單

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

### 3. 建立租戶（電商平台）

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

### 4. 建立商店

```bash
curl -X POST http://localhost:3000/api/v1/tenants/1/shops \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "shop": {
      "name": "主商店",
      "description": "這是主商店"
    }
  }'
```

### 5. 建立商品

```bash
curl -X POST http://localhost:3000/api/v1/tenants/1/shops/1/products \
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

### 6. 建立訂單

```bash
curl -X POST http://localhost:3000/api/v1/tenants/1/shops/1/orders \
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
- 訂單建立時，庫存扣減和訂單建立必須要麼全部成功，要麼全部失敗
- 訂單取消時，庫存回退和訂單狀態更新必須要麼全部成功，要麼全部失敗

### 錯誤處理

- 在 Controller 中使用 `rescue_from` 統一處理錯誤
- 在 Service Objects 中使用 `begin/rescue` 處理錯誤並回傳統一的錯誤格式

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

## 常見問題

### Q: 如何確保多租戶資料隔離？

A: 使用 `acts_as_tenant` gem，所有查詢都會自動加入 `tenant_id` 條件。在 Controller 中透過 `set_current_tenant` 設定當前租戶。

### Q: 訂單建立時如何確保庫存正確扣減？

A: 使用 `ActiveRecord::Base.transaction` 確保訂單建立和庫存扣減的原子性。如果其中任何一步失敗，整個交易會回滾。

### Q: 如何處理併發訂單？

A: 使用資料庫交易和原子操作（如 `update_column`）來確保併發安全。


## 套件選用

### Spree vs Solidus

Solidus 是從 Spree 分支出來的，因此它們有共同的歷史和許多相似之處，但在發展方向、社群焦點和架構重點上，兩者已產生了顯著的差異。

項目,Spree,Solidus
起源,原創的 Ruby on Rails 電商引擎先驅。,於 2015 年從 Spree 的 2.4 版本 分支出來（Fork）。
分支原因,Spree 經歷了公司收購和商業化嘗試（如 Wombat），社群成員認為開發方向變得緩慢且代碼品質有所下降。,社群主導，為了維持更高的 代碼品質、穩定性 和 企業級功能 而誕生。

項目,Spree,Solidus
代碼品質,穩定性改善中，但因歷經多次重大轉型，有時版本間的差異較大。,極度專注於代碼品質與穩定性，被認為在 RoR 核心代碼上更為精煉。
Headless 支援,極佳。 這是它的主要發展方向，提供標準化的 PWA 前端解決方案。,良好。 提供強大的 API 支援，但 Headless 不是其唯一或首要的發展重點。
社群與維護,活躍，但重點轉向 API 和現代化前端。由 Spree 團隊和廣大社群共同維護。,活躍，專注於核心 Rails 引擎的開發。許多企業級使用者貢獻代碼，由 Stembolt（現在是 RFS）等公司支持。
外掛 (Extensions),數量較多，但品質參差不齊，部分舊外掛可能與 Headless 架構不相容。,數量相對較少，但通常有更好的維護和更高的企業級品質。
升級路徑,較為激進。為了現代化，部分版本升級可能需要較多的遷移工作。,較為平穩。 致力於向後兼容性，企業使用者在升級時通常面臨較少的阻礙。