require 'rspec'
require 'rspec/collection_matchers'
require_relative 'bootstrap'

describe ShippingLabelGenerator do
  attr_reader :product, :shipping_label_generator

  before(:each) do
    @product = Product.new(name: 'Iron Maiden - The Trooper', type: :digital)
    @shipping_label_generator = ShippingLabelGenerator.new
  end

  it "produce shipping label for product" do
    result = @shipping_label_generator.produce(@product)

    expect(result).to eq("generating shipping label for product Iron Maiden - The Trooper ")
  end

  it "produce shipping label for product with message" do
    result = @shipping_label_generator.produce(@product, "Item isento de impostos...")

    expect(result).to eq("generating shipping label for product Iron Maiden - The Trooper Item isento de impostos...")
  end
end

describe Membership do
  attr_reader :customer

  it "active account" do
    customer = Customer.new(name: "André", email: "andre@email")
    membership = Membership.new
    expect(membership.activeAccount(customer)).to eq("Active account of André")
  end
end

describe OrderItemFactory do
  attr_reader :order_item_factory

  before(:each) do
    @order_item_factory = OrderItemFactory.new(double('order'))
  end

  it "create a factory that make a physical order item" do
    product = Product.new(name: 'Awesome physical product', type: :physical)
    expect(@order_item_factory.create(product)).to be_an_instance_of(OrderItemPhysical)
  end

  it "create a factory that make a book order item" do
    product = Product.new(name: 'Awesome book', type: :book)
    expect(@order_item_factory.create(product)).to be_an_instance_of(OrderItemBook)
  end

  it "create a factory that make a membership order item" do
    product = Product.new(name: 'Air and Space Magazine', type: :membership)
    expect(@order_item_factory.create(product)).to be_an_instance_of(OrderItemMembership)
  end

  it "create a factory that make a digital order item" do
    product = Product.new(name: 'Iron Maiden - The Trooper', type: :digital)
    expect(@order_item_factory.create(product)).to be_an_instance_of(OrderItemDigital)
  end
end

describe OrderBuilder do
  subject { 
    OrderBuilder.new(Customer.new(name: "André", email: "andre@email"))
      .add_product(Product.new(name: 'Awesome physical product', type: :physical))
      .add_product(Product.new(name: 'Awesome book', type: :book))
      .add_product(Product.new(name: 'Air and Space Magazine', type: :membership))
      .add_product(Product.new(name: 'Iron Maiden - The Trooper', type: :digital))
      .build 
  }

  it { is_expected.to have(4).items }
end
