module Mocks

  module Stripe

    def mock_stripe!
      # Return an object that contains a unique id for Customer, Invoice or InvoiceItem
      allow_any_instance_of(::Stripe::APIOperations::Create).to receive(:create).and_return(
        OpenStruct.new(id: Faker::Number.unique(10))
      )
    end

  end

end
