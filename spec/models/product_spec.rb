require "rails_helper"

RSpec.describe Product, type: :model do
  subject(:product) { build(:product) }

  describe "associations" do
    # 商品必須隸屬某個商店
    it { is_expected.to belong_to(:shop) }
    # 刪除商品時應一併刪除訂單項目
    it { is_expected.to have_many(:order_items).dependent(:destroy) }
    # 商品可透過訂單項目關聯多筆訂單
    it { is_expected.to have_many(:orders).through(:order_items) }
  end

  describe "validations" do
    # 商品名稱必填
    it { is_expected.to validate_presence_of(:name) }
    # 價格必填
    it { is_expected.to validate_presence_of(:price) }
    # 價格需大於 0
    it { is_expected.to validate_numericality_of(:price).is_greater_than(0) }
    # 庫存量必填
    it { is_expected.to validate_presence_of(:stock_quantity) }
    # 庫存量需 ≥ 0
    it { is_expected.to validate_numericality_of(:stock_quantity).is_greater_than_or_equal_to(0) }

    # 同一商店內 SKU 不可重複
    it "validates uniqueness of sku scoped to shop" do
      create(:product, shop: product.shop, sku: "SKU1234")
      duplicate = build(:product, shop: product.shop, sku: "SKU1234")

      expect(duplicate).to be_invalid
      expect(duplicate.errors[:sku]).to include("has already been taken")
    end
  end

  describe "#in_stock?" do
    # 當庫存為正且狀態啟用應視為可售
    it "returns true when quantity positive and active" do
      product.stock_quantity = 5
      product.status = Product::STATUS_ACTIVE
      expect(product.in_stock?).to be(true)
    end

    # 庫存為零時應顯示缺貨
    it "returns false when quantity zero" do
      product.stock_quantity = 0
      expect(product.in_stock?).to be(false)
    end

    # 狀態停用時即使有庫存也視為不可售
    it "returns false when status inactive" do
      product.status = Product::STATUS_INACTIVE
      expect(product.in_stock?).to be(false)
    end
  end

  describe "#decrease_stock!" do
    # 成功扣庫存至零時狀態應改為缺貨
    it "reduces stock and switches status when reaches zero" do
      product = create(:product, stock_quantity: 2, status: Product::STATUS_ACTIVE)

      expect { product.decrease_stock!(2) }.to change { product.reload.stock_quantity }.from(2).to(0)
      expect(product.status).to eq(Product::STATUS_OUT_OF_STOCK)
    end

    # 非正整數數量應拋出錯誤
    it "raises error when quantity invalid" do
      product = create(:product)
      expect { product.decrease_stock!(0) }.to raise_error(Product::InvalidStockQuantityError)
    end

    # 庫存不足時應拋出錯誤
    it "raises error when stock insufficient" do
      product = create(:product, stock_quantity: 1)
      expect { product.decrease_stock!(2) }.to raise_error(Product::InsufficientStockError)
    end
  end

  describe "#increase_stock!" do
    # 增加庫存後應恢復為可販售狀態
    it "increments stock and restores status" do
      product = create(:product, stock_quantity: 0, status: Product::STATUS_OUT_OF_STOCK)

      expect { product.increase_stock!(3) }.to change { product.reload.stock_quantity }.from(0).to(3)
      expect(product.status).to eq(Product::STATUS_ACTIVE)
    end

    # 非正整數數量應拋出錯誤
    it "raises error when quantity invalid" do
      product = create(:product)
      expect { product.increase_stock!(0) }.to raise_error(Product::InvalidStockQuantityError)
    end
  end
end

