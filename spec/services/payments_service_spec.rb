describe PaymentsService do

  let(:user) { create(:user) }
  let(:identifier) { create(:identifier) }
  let(:resource) { create(:resource, identifier: identifier, total_file_size: 6_234_567_890) }
  let(:options) { {} }
  let(:subject) { PaymentsService.new(user, resource, options) }

  describe '#initialize' do
    it 'sets proper attributes' do
      expect(subject.user).to eq(user)
      expect(subject.resource).to eq(resource)
      expect(subject.options).to eq(options)
    end
  end

  describe '#total_amount' do
    it 'sets proper attributes' do
      expect(subject.total_amount).to eq(180)
    end
  end

  describe '#checkout_options' do
    let(:checkout_options) do
      {
        mode: 'payment',
        ui_mode: 'embedded',
        line_items: [{
          quantity: 1,
          price_data: {
            currency: 'usd',
            product_data: {
              name: "Data Publishing Charge for #{identifier} (6.23 GB)"
            },
            unit_amount: 18_000
          }
        }]
      }
    end

    it 'has correct values' do
      expect(subject.checkout_options).to eq(checkout_options)
    end
  end
end
