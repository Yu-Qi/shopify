# UsersController
# 處理用戶相關的 API
# 取得當前用戶資訊

module Api
  module V1
    class UsersController < ApplicationController
      before_action :authenticate_user!

      # 取得當前用戶資訊
      def me
        seller_profile = current_seller_profile
        buyer_profile = current_buyer_profile
        render json: {
          id: current_user.id,
          name: current_user.name,
          email: current_user.email,
          seller_profile: seller_profile && {
            id: seller_profile.id,
            display_name: seller_profile.display_name,
            tenants_count: seller_profile.tenants.count
          },
          buyer_profile: buyer_profile && {
            id: buyer_profile.id,
            display_name: buyer_profile.display_name
          }
        }, status: :ok
      end
    end
  end
end

