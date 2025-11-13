FactoryBot.define do
  factory :payment do
    association :order
    buyer_profile do
      order.buyer_profile || create(:buyer_profile)
    end
    amount { order.total_amount }
    status { Payment::STATUSES[:completed] }
    payment_method { "credit_card" }
    transaction_reference { SecureRandom.uuid }
    metadata { { gateway: "test" } }

    before(:create) do |payment|
      if payment.order.buyer_profile.nil?
        payment.order.update!(buyer_profile: payment.buyer_profile)
      end
    end
  end
end

