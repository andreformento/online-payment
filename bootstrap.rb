class Payment
  attr_reader :authorization_number, :amount, :invoice, :order, :payment_method, :paid_at

  def initialize(attributes = {})
    @authorization_number, @amount = attributes.values_at(:authorization_number, :amount)
    @invoice, @order = attributes.values_at(:invoice, :order)
    @payment_method = attributes.values_at(:payment_method)
  end

  def pay(paid_at = Time.now)
    @amount = order.total_amount
    @authorization_number = Time.now.to_i
    @invoice = Invoice.new(billing_address: order.address, shipping_address: order.address, order: order)
    @paid_at = paid_at
    order.close(@paid_at)
  end

  def paid?
    !paid_at.nil?
  end
end

class Invoice
  attr_reader :billing_address, :shipping_address, :order

  def initialize(attributes = {})
    @billing_address = attributes.values_at(:billing_address)
    @shipping_address = attributes.values_at(:shipping_address)
    @order = attributes.values_at(:order)
  end
end

class OrderBuilder
  attr_reader :order_item_factory, :order

  def initialize(customer, overrides = {})
    @order = Order.new(customer, overrides)
    @order_item_factory = OrderItemFactory.new(@order)
  end

  def add_product(product)
    @order.add_order_item(order_item_factory.create(product))
    self
  end

  def build
    @order
  end
end

class Order
  attr_reader :customer, :items, :payment, :address, :closed_at

  def initialize(customer, overrides = {})
    @customer = customer
    @items = []
    @address = overrides.fetch(:address) { Address.new(zipcode: '45678-979') }
  end

  def add_order_item(order_item)
    @items << order_item
  end

  def total_amount
    @items.map(&:total).inject(:+)
  end

  def close(closed_at = Time.now)
    close_all_items
    @closed_at = closed_at
  end

  private def close_all_items
    @items.each{|item| item.process}
  end

end

class OrderItem
  attr_reader :order, :product

  def initialize(order, product)
    @order = order
    @product = product
  end

  def process
    raise "You cannot call this method"
  end

  def total
    10
  end
end

class ShippingLabelGenerator
  def produce(product, message = "")
    p "generating shipping label for product #{product.name} #{message}"
  end
end

class EmailService
  def send(customer, message)
    p "Send email to #{customer.name} <#{customer.email}>: #{message}"
  end
end

class VoucherService
  def apply(customer, voucherValue)
    customer.applyVoucher(voucherValue)
  end
end

class OrderItemPhysical < OrderItem
  attr_reader :shipping_label_generator

  def initialize(order, product)
    super
    @shipping_label_generator = ShippingLabelGenerator.new
  end
  def process
    shipping_label_generator.produce(@product)
    #p "OrderItemPhysical: Se o pagamento for para um item físico, você deverá gerar um shipping label para o mesmo ser colocado na caixa do envio"
  end
end

class OrderItemMembership < OrderItem
  attr_reader :membership, :email_service

  def initialize(order, product)
    super
    @membership = Membership.new
    @email_service = EmailService.new
  end

  def process
    @membership.activeAccount(@order.customer)
    @email_service.send(@order.customer, "Sua assinatura foi ativada")
    #p "OrderItemMembership: Caso o pagamento seja uma assinatura de serviço, você precisa ativar a assinatura, e notificar o usuário através de e-mail sobre isto"
  end
end

class OrderItemBook < OrderItem
  attr_reader :shipping_label_generator

  def initialize(order, product)
    super
    @shipping_label_generator = ShippingLabelGenerator.new
  end
  def process
    shipping_label_generator.produce(@product, "Item isento de impostos conforme disposto na Constituição Art. 150, VI, d")
    #p "OrderItemBook: Caso o pagamento seja um livro comum, você precisa gerar o shipping label com uma notificação de que trata-se de um item isento de impostos conforme disposto na Constituição Art. 150, VI, d"
  end
end

class OrderItemDigital < OrderItem
  attr_reader :email_service

  def initialize(order, product)
    super
    @email_service = EmailService.new
  end

  def process
    @email_service.send(@order.customer, "Sua compra com o item #{@product.name} foi efetuada e você ganhou um voucher de 10 reais")
    @order.customer.applyVoucher(10)
    # p "OrderItemDigital: Caso o pagamento seja de alguma mídia digital (música, vídeo), além de enviar a descrição da compra por e-mail ao comprador, conceder um voucher de desconto de R$ 10 ao comprador associado ao pagamento"
  end
end

class OrderItemFactory
  attr_reader :order, :items

  def initialize(order)
    @order = order
    @items = {
      :physical => OrderItemPhysical,
      :book => OrderItemBook,
      :digital => OrderItemDigital,
      :membership => OrderItemMembership
    }
  end

  def create(product)
    @items[product.type].new(@order, product)
  end
end

class Product
  # use type to distinguish each kind of product: physical, book, digital, membership, etc.
  attr_reader :name, :type

  def initialize(name:, type:)
    @name, @type = name, type
  end
end

class Address
  attr_reader :zipcode

  def initialize(zipcode:)
    @zipcode = zipcode
  end
end

class CreditCard
  def self.fetch_by_hashed(code)
    CreditCard.new
  end
end

class Customer
  attr_reader :name, :email, :vouchers

  def initialize(name:, email:)
    @name, @email = name, email
    @vouchers = []
  end

  def applyVoucher(value)
    @vouchers << value
  end
end

class Membership
  def activeAccount(customer)
    p "Active account of #{customer.name}"
  end
end

if __FILE__ == $0

  # Book Example (build new payments if you need to properly test it)
  andre = Customer.new(name: "André", email: "andre@email")

  book_order = OrderBuilder.new(andre)
    .add_product(Product.new(name: 'Awesome physical product', type: :physical))
    .add_product(Product.new(name: 'Awesome book', type: :book))
    .add_product(Product.new(name: 'Air and Space Magazine', type: :membership))
    .add_product(Product.new(name: 'Iron Maiden - The Trooper', type: :digital))
    .build

  payment_book = Payment.new(order: book_order, payment_method: CreditCard.fetch_by_hashed('43567890-987654367'))
  payment_book.pay
  p payment_book.paid? # < true
  p payment_book.order.items.first.product.type

end
