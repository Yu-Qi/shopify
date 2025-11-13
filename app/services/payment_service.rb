class PaymentService < ApplicationService
  def initialize(order, buyer_profile, params)
    @order = order
    @buyer_profile = buyer_profile
    @params = params
    @tenant = order.tenant
  end

  def call
    return failure(['訂單已經付款'], code: ErrorCodes::Order::Payment::ALREADY_PAID) if @order.payment.present?
    return failure(['訂單目前狀態無法付款'], code: ErrorCodes::Order::Payment::INVALID_STATE) unless @order.status == Order::STATUS_PENDING
    return failure(['訂單已賦予其他買家'], code: ErrorCodes::Order::Payment::UNAUTHORIZED) if @order.buyer_profile && @order.buyer_profile != @buyer_profile

    amount = BigDecimal(@params[:amount].to_s)
    return failure(['付款金額與訂單金額不符'], code: ErrorCodes::Order::Payment::INVALID_AMOUNT) unless amounts_match?(amount, @order.total_amount)

    ActiveRecord::Base.transaction do
      ActsAsTenant.current_tenant = @tenant

      @order.update!(buyer_profile: @buyer_profile) unless @order.buyer_profile

      payment = Payment.create!(
        order: @order,
        buyer_profile: @buyer_profile,
        amount: amount,
        status: Payment::STATUSES[:completed],
        payment_method: @params[:payment_method],
        transaction_reference: @params[:transaction_reference],
        metadata: @params[:metadata]
      )

      @order.update!(status: Order::STATUS_PROCESSING)

      success(payment)
    end
  rescue ActiveRecord::RecordInvalid => e
    failure(e.record.errors.full_messages)
  rescue StandardError => e
    Rails.logger.error("PaymentService error: #{e.message}")
    failure(
      ["付款時發生錯誤：#{e.message}"],
      status: :internal_server_error,
      code: ErrorCodes::Order::Payment::UNEXPECTED_ERROR
    )
  end

  private

  def amounts_match?(amount_a, amount_b)
    amount_a.round(2) == amount_b.round(2)
  end
end

