FactoryBot.define do
  factory :order_item do
    association :order
    product do
      association :product, shop: order.shop
    end
    quantity { 1 }
    price { product.price }

    after(:build) do |order_item|
      order_item.tenant = order_item.order.shop.tenant if order_item.respond_to?(:tenant=)
      order_item.price ||= order_item.product.price
    end
  end
end

