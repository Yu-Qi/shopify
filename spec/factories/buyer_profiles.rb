FactoryBot.define do
  factory :buyer_profile do
    association :user
    display_name { Faker::Name.name }
  end
end

