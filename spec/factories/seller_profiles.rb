FactoryBot.define do
  factory :seller_profile do
    association :user
    display_name { Faker::Company.name }
  end
end

