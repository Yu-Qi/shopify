FactoryBot.define do
  factory :order do
    association :shop, strategy: :create
    customer_name { Faker::Name.name }
    customer_email { Faker::Internet.email }
    shipping_address { Faker::Address.full_address }
    status { Order::STATUS_PENDING }

    transient do
      item_count { 1 }
      item_quantity { 1 }
    end

    after(:build) do |order, evaluator|
      order.tenant = order.shop.tenant if order.respond_to?(:tenant=)

      ActsAsTenant.with_tenant(order.shop.tenant) do
        order.order_items = order.order_items.to_a

        if order.order_items.empty?
          evaluator.item_count.times do
            product = create(:product, shop: order.shop)
            order.order_items.build(
              product: product,
              quantity: evaluator.item_quantity,
              price: product.price,
              tenant: order.shop.tenant
            )
          end
        else
          order.order_items.each do |item|
            item.tenant = order.shop.tenant if item.respond_to?(:tenant=)
          end
        end

        order.total_amount = order.order_items.sum { |item| item.price * item.quantity }
      end
    end

    after(:create, &:reload)
  end
end

