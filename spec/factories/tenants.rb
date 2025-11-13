FactoryBot.define do
  factory :tenant do
    association :seller_profile
    sequence(:name) { |n| "Tenant #{n}" }
    description { "測試租戶描述" }
    domain { nil }
  end
end

