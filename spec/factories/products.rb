FactoryBot.define do
  factory :product do
    association :shop
    name { Faker::Commerce.product_name }
    description { Faker::Commerce.material }
    price { BigDecimal("99.99") }
    stock_quantity { 10 }
    sku { SecureRandom.hex(4) }
    status { Product::STATUS_ACTIVE }

    after(:build) do |product|
      product.tenant = product.shop.tenant if product.respond_to?(:tenant=)
    end
  end
end

