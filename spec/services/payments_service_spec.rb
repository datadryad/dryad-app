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

    context 'if there is an institution that does not cover LDF' do
      let(:prev_files_size) { 0 }
      let(:new_files_size) { 11_000_000_000 }
      let(:covers_ldf) { false }
      let!(:tenant) { create(:tenant, payment_plan: '2025', covers_dpc: true, covers_ldf: covers_ldf) }
      let(:identifier) { create(:identifier, last_invoiced_file_size: prev_files_size) }
      let(:resource) { create(:resource, identifier: identifier, tenant: tenant, total_file_size: new_files_size) }

      it 'has correct values and does not show keys with 0 fee' do
        expect(subject.checkout_options).to eq(
          {
            mode: 'payment',
            ui_mode: 'embedded',
            line_items: [{
              quantity: 1,
              price_data: {
                currency: 'usd',
                product_data: {
                  name: "Large data fee for #{identifier} (11 GB)"
                },
                unit_amount: 25_900
              }
            }]
          }
        )
      end
    end
  end
end
