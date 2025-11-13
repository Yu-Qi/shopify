# AuthController
# 處理用戶認證相關的 API
# 包括登入、註冊、登出

module Api
  module V1
    class AuthController < ApplicationController
      # 跳過認證檢查（因為這是認證端點）
      skip_before_action :authenticate_user!, only: [:login, :register]

      # 用戶註冊
      def register
        user = User.new(user_params)
        
        if user.save
          # 註冊成功後，自動登入（生成 token）
          token = user.generate_token
          render json: {
            message: '註冊成功',
            user: {
              id: user.id,
              name: user.name,
              email: user.email
            },
            token: token
          }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # 用戶登入
      def login
        user = User.find_by(email: login_params[:email])
        
        # 驗證用戶是否存在且密碼正確
        if user && user.authenticate(login_params[:password])
          # 生成 token
          token = user.generate_token
          render json: {
            message: '登入成功',
            user: {
              id: user.id,
              name: user.name,
              email: user.email
            },
            token: token
          }, status: :ok
        else
          render json: { error: '電子郵件或密碼錯誤' }, status: :unauthorized
        end
      end

      # 用戶登出
      def logout
        # JWT 是無狀態的，所以登出主要是客戶端刪除 token
        # 如果需要，可以在這裡實作 token 黑名單機制
        render json: { message: '登出成功' }, status: :ok
      end

      private

      def user_params
        params.require(:user).permit(:name, :email, :password, :password_confirmation)
      end

      def login_params
        params.require(:user).permit(:email, :password)
      end
    end
  end
end

