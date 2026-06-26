module Mocks
  module Stripe

    def mock_stripe!
      id = Faker::Number.unique(10)

      allow(::Stripe::Invoice).to receive(:create).and_return(
        OpenStruct.new(id: id, send_invoice: OpenStruct.new(id: id))
      )
      allow(::Stripe::InvoiceItem).to receive(:create).and_return(
        OpenStruct.new(id: id, send_invoice: OpenStruct.new(id: id))
      )
      allow(::Stripe::Customer).to receive(:create).and_return(
        OpenStruct.new(id: id, send_invoice: OpenStruct.new(id: id))
      )
    end
  end
end
