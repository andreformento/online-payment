require 'rspec'
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
