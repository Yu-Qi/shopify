module Api
  module V1
    class PaymentsController < ApplicationController
      before_action :authenticate_user!
      before_action :require_buyer_profile!

      def create
        order = find_order
        return unless order

        result = PaymentService.call(order, current_buyer_profile, payment_params.to_h)

        if result[:success]
          render json: serialize_payment(result[:data]), status: :created
        else
          render json: { errors: result[:errors], error_code: result[:error_code] }, status: result[:status]
        end
      end

      private

      def find_order
        order = ActsAsTenant.without_tenant { Order.find_by(id: params[:order_id]) }
        unless order
          render json: { error: '訂單不存在' }, status: :not_found
          return nil
        end
        order
      end

      def payment_params
        params.require(:payment).permit(:amount, :payment_method, :transaction_reference, metadata: {})
      end

      def serialize_payment(payment)
        {
          id: payment.id,
          order_id: payment.order_id,
          amount: payment.amount.to_s,
          status: payment.status,
          payment_method: payment.payment_method,
          transaction_reference: payment.transaction_reference
        }
      end
    end
  end
end

