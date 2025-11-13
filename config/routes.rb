Rails.application.routes.draw do
  # API 路由命名空間
  namespace :api do
    namespace :v1 do
      # 用戶認證相關
      post 'auth/login', to: 'auth#login'
      post 'auth/register', to: 'auth#register'
      post 'auth/logout', to: 'auth#logout'

      resource :seller_profile, only: [:show, :create, :destroy]
      resource :buyer_profile, only: [:show, :create, :destroy]

      # 租戶管理（用戶可以建立和管理自己的電商）
      resources :tenants, only: [:create, :show, :update, :destroy]

      # 商店管理（由 token 判斷租戶）
      resources :shops, only: [:index, :create, :show, :update, :destroy] do
        # 商品管理
        resources :products, only: [:index, :create, :show, :update, :destroy]

        # 訂單管理
        resources :orders, only: [:index, :create, :show, :update] do
          member do
            patch :cancel  # 取消訂單
            patch :complete  # 完成訂單
          end
        end
      end

      # 當前用戶資訊
      get 'me', to: 'users#me'
      get 'my-tenants', to: 'tenants#my_tenants'

      post 'orders/:order_id/payments', to: 'payments#create'
    end
  end

  # 健康檢查端點
  get 'health', to: 'health#check'
end

