source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.3.4'

# Rails 核心框架
gem 'rails', '~> 7.1.0'

# 資料庫
gem 'pg', '~> 1.5'  # PostgreSQL 資料庫驅動

# 多租戶支援 - 使用 acts_as_tenant 來處理多租戶隔離
gem 'acts_as_tenant'

# API 相關
gem 'rack-cors'  # 處理跨域請求

# 安全性
gem 'bcrypt', '~> 3.1.7'  # 密碼加密
gem 'jwt'  # JWT token 認證

# 資料驗證和序列化
gem 'active_model_serializers'  # API 序列化

# 工具類
gem 'pry-rails'  # 開發時除錯工具
gem 'annotate'  # 自動生成 model 註解

# 後台任務
gem 'sidekiq'  # 背景任務處理
gem 'redis'  # Sidekiq 需要 Redis

# 日誌和監控
gem 'lograge'  # 結構化日誌

# 測試
group :development, :test do
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'faker'
end

group :development do
  gem 'listen', '~> 3.3'
  gem 'spring'
end

