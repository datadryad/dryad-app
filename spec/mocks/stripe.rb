module Mocks
  module Stripe

    def mock_stripe!
      id = Faker::Number.unique(10)
      # Return an object that contains a unique id for Customer, Invoice or InvoiceItem
      allow_any_instance_of(::Stripe::APIOperations::Create).to receive(:create).and_return(
        OpenStruct.new(id: id, send_invoice: OpenStruct.new(id: id))
      )
    end
  end
end
