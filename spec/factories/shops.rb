FactoryBot.define do
  factory :shop do
    association :tenant
    sequence(:name) { |n| "Shop #{n}" }
    description { "測試商店描述" }
    status { Shop::STATUS_ACTIVE }
  end
end

