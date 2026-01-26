describe PaymentsService do

  let(:user) { create(:user) }
  let(:identifier) { create(:identifier) }
  let(:total_file_size) { 6_234_567_890 }
  let(:resource) { create(:resource, identifier: identifier, total_file_size: total_file_size) }
  let(:options) { {} }
  let(:subject) { PaymentsService.new(user, resource, options) }

  describe '#initialize' do
    it 'sets proper attributes' do
      expect(subject.user).to eq(user)
      expect(subject.resource).to eq(resource)
      expect(subject.options).to eq(options)
      expect(subject.has_discount).to be_falsey
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
              name: "Data Publishing Charge for #{identifier} (6.23 GB) submitted by #{resource.submitter.name}"
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
      let(:prev_files_size) { nil }
      let(:new_files_size) { 11_000_000_000 }
      let(:covers_ldf) { false }
      let!(:tenant) { create(:tenant) }
      let!(:payment_conf) { create(:payment_configuration, partner: tenant, payment_plan: '2025', covers_dpc: true, covers_ldf: covers_ldf) }
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
                  name: "Large data fee for #{identifier} (11 GB) submitted by #{resource.submitter.name}"
                },
                unit_amount: 25_900
              }
            }]
          }
        )
      end
    end

    context 'when fees contain a coupon ID' do
      let(:identifier) { create(:identifier, payment_type: 'waiver') }
      let(:total_file_size) { 16_320_000_000 }

      it 'is true' do
        expect(subject.checkout_options).to eq(
          {
            mode: 'payment',
            ui_mode: 'embedded',
            discounts: [{ coupon: 'FEE_WAIVER_2025' }],
            line_items: [{
              quantity: 1,
              price_data: {
                currency: 'usd',
                product_data: {
                  name: "Data Publishing Charge for #{identifier} (16.32 GB) submitted by #{resource.submitter.name}"
                },
                unit_amount: 52_000
              }
            }]
          }
        )
        expect(subject.total_amount).to eq(340)
      end
    end
  end

  describe 'has_discount' do
    context 'by default' do
      it 'it is false' do
        expect(subject.has_discount).to be_falsey
      end
    end

    context 'when fees contain a coupon ID' do
      context 'when payer is a waiver' do
        let(:identifier) { create(:identifier, payment_type: 'waiver') }

        context 'under free limit' do
          let(:total_file_size) { 6_320_000_000 }

          it 'is true' do
            expect(subject.has_discount).to be_truthy
          end
        end

        context 'over free limit' do
          let(:total_file_size) { 16_320_000_000 }

          it 'is true' do
            expect(subject.has_discount).to be_truthy
          end
        end
      end

      context 'when payer is not a waiver' do
        let(:identifier) { create(:identifier) }
        context 'under free limit' do
          let(:total_file_size) { 6_320_000_000 }

          it 'is false' do
            expect(subject.has_discount).to be_falsey
          end
        end

        context 'over free limit' do
          let(:total_file_size) { 16_320_000_000 }

          it 'is false' do
            expect(subject.has_discount).to be_falsey
          end
        end
      end
    end
  end
end
