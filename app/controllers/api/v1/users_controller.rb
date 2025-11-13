# UsersController
# 處理用戶相關的 API
# 取得當前用戶資訊

module Api
  module V1
    class UsersController < ApplicationController
      before_action :authenticate_user!

      # 取得當前用戶資訊
      def me
        render json: {
          id: current_user.id,
          name: current_user.name,
          email: current_user.email,
          tenants_count: current_user.tenants.count
        }, status: :ok
      end
    end
  end
end

