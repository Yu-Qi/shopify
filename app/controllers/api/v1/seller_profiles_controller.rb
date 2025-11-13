module Api
  module V1
    class SellerProfilesController < ApplicationController
      before_action :authenticate_user!

      def show
        profile = current_seller_profile
        if profile
          render json: serialize_profile(profile), status: :ok
        else
          render json: { error: '店家資料不存在' }, status: :not_found
        end
      end

      def create
        if current_seller_profile
          render json: { error: '店家資料已存在' }, status: :unprocessable_entity
          return
        end

        profile = current_user.build_seller_profile(profile_params)
        if profile.save
          render json: serialize_profile(profile), status: :created
        else
          render json: { errors: profile.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        profile = current_seller_profile
        unless profile
          render json: { error: '店家資料不存在' }, status: :not_found
          return
        end

        profile.destroy!
        render json: { message: '店家資料已刪除' }, status: :ok
      end

      private

      def profile_params
        params.require(:seller_profile).permit(:display_name)
      end

      def serialize_profile(profile)
        {
          id: profile.id,
          display_name: profile.display_name,
          tenants_count: profile.tenants.count
        }
      end
    end
  end
end

