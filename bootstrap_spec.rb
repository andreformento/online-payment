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

describe OrderItem do
  attr_reader :order

  before(:each) do
    @order = OrderBuilder.new(Customer.new(name: "André", email: "andre@email")).build
  end

  # Se o pagamento for para um item físico, você deverá gerar um shipping label para o mesmo ser colocado na caixa do envio"
  it "should generate shipping label for order item physical" do
    product = Product.new(name: 'Awesome physical product', type: :physical)
    expect(OrderItemPhysical.new(@order, product).process).to eq("generating shipping label for product Awesome physical product ")
  end

  # Caso o pagamento seja uma assinatura de serviço, você precisa ativar a assinatura, e notificar o usuário através de e-mail sobre isto"
  it "should generate shipping label for order item membership" do
    product = Product.new(name: 'Air and Space Magazine', type: :membership)
    expect(OrderItemMembership.new(@order, product).process).to eq("Active account of André; Send email to André <andre@email>: Sua assinatura foi ativada")
  end

  # Caso o pagamento seja um livro comum, você precisa gerar o shipping label com uma notificação de que trata-se de um item isento de impostos conforme disposto na Constituição Art. 150, VI, d"
  it "should generate shipping label for order item book" do
    product = Product.new(name: 'Awesome book', type: :book)
    expect(OrderItemBook.new(@order, product).process).to eq("generating shipping label for product Awesome book Item isento de impostos conforme disposto na Constituição Art. 150, VI, d")
  end

  # Caso o pagamento seja de alguma mídia digital (música, vídeo), além de enviar a descrição da compra por e-mail ao comprador, conceder um voucher de desconto de R$ 10 ao comprador associado ao pagamento"
  it "should generate shipping label for order item digital" do
    product = Product.new(name: 'Iron Maiden - The Trooper', type: :digital)
    expect(OrderItemDigital.new(@order, product).process).to eq("Send email to André <andre@email>: Sua compra com o item Iron Maiden - The Trooper foi efetuada e você ganhou um voucher de 10 reais")
  end
end
