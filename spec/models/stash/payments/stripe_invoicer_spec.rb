# require 'ostruct'
# require 'action_controller'

module Stash
  module Payments
    describe StripeInvoicer do
      include Mocks::Salesforce
      include Mocks::Stripe

      let(:identifier) { create(:identifier, old_payment_system: false, last_invoiced_file_size: 0) }
      let(:resource) { create(:resource, identifier: identifier, total_file_size: 100) }
      let(:author) { resource.owner_author }
      let(:invoicer) { Stash::Payments::StripeInvoicer.new(resource) }
      let(:invoice_id) { nil }
      let!(:payment) do
        create(:resource_payment,
               resource: resource,
               pay_with_invoice: true,
               invoice_id: invoice_id,
               invoice_details: {
                 'author_id' => author.id,
                 'customer_name' => 'Customer Name',
                 'customer_email' => 'customer.email@example.com'
               })
      end

      before do
        mock_salesforce!
        mock_stripe!
        allow(invoicer).to receive(:lookup_prior_stripe_customer_id).and_return('stripe_customer_id')
        allow(Stripe::Invoice).to receive(:retrieve).and_return(OpenStruct.new({ id: invoice_id, status: 'open' }))
      end

      describe 'initializer' do
        it 'sets resource' do
          expect(invoicer.resource).to eq(resource)
        end
      end

      describe '#invoice_created' do
        it 'returns false' do
          expect(invoicer.invoice_created?).to be_falsey
        end

        context 'with invoice_id set' do
          let(:invoice_id) { 'in_voice-id' }

          it 'returns true' do
            expect(invoicer.invoice_created?).to be_truthy
          end
        end
      end

      describe '#invoice_paid' do
        let(:invoice_id) { 'in_voice-id' }

        it 'returns false' do
          expect(Stripe::Invoice).to receive(:retrieve)
          expect(invoicer.invoice_paid?).to be_falsey
        end

        context 'with paid invoice' do
          before { allow(Stripe::Invoice).to receive(:retrieve).and_return(OpenStruct.new({ id: invoice_id, status: 'paid' })) }
          it 'returns true' do
            expect(Stripe::Invoice).to receive(:retrieve)
            expect(invoicer.invoice_paid?).to be_truthy
          end
        end

        context 'with void invoice' do
          before do
            allow(Stripe::Invoice).to receive(:retrieve)
              .with(invoice_id)
              .and_return(OpenStruct.new({ id: invoice_id, status: 'void', latest_revision: 'in_voice-id-new' })).once
          end

          it 'updates resource invoice and returns true' do
            allow(Stripe::Invoice).to receive(:retrieve)
              .with('in_voice-id-new')
              .and_return(OpenStruct.new({ id: 'in_voice-id-new', status: 'paid' })).once
            expect(Stripe::Invoice).to receive(:retrieve).twice
            expect(invoicer.invoice_paid?).to be_truthy
            expect(resource.payment.invoice_id).to eq('in_voice-id-new')
          end

          it 'updates resource invoice and returns false' do
            allow(Stripe::Invoice).to receive(:retrieve)
              .with('in_voice-id-new')
              .and_return(OpenStruct.new({ id: 'in_voice-id-new', status: 'open' })).once
            expect(Stripe::Invoice).to receive(:retrieve).twice
            expect(invoicer.invoice_paid?).to be_falsey
            expect(resource.payment.invoice_id).to eq('in_voice-id-new')
          end
        end
      end

      describe '#create_invoice' do
        context 'if total fee is zero' do
          before do
            allow_any_instance_of(ResourceFeeCalculatorService).to receive(:calculate).and_return(
              { storage_fee: 0, storage_fee_label: 'Some line item name', total: 0 }
            )
          end

          it 'returns false' do
            expect(Stripe::Invoice).not_to receive(:create)
            expect(invoicer.create_invoice).to be_falsey
          end

          context 'if this is a fee waiver user' do
            let(:identifier) { create(:identifier, old_payment_system: false, payment_type: 'waiver') }

            it 'generates an invoice' do
              invoice = OpenStruct.new(id: 1, send_invoice: OpenStruct.new(id: 1))
              expect(Stripe::Invoice).to receive(:create).with(
                {
                  auto_advance: true,
                  collection_method: 'send_invoice',
                  customer: 'stripe_customer_id',
                  days_until_due: 30,
                  description: "Dryad deposit #{identifier}, #{resource.title}"
                }
              ).and_return(invoice)
              expect(Stripe::InvoiceItem).to receive(:create).with(
                {
                  customer: 'stripe_customer_id',
                  invoice: 1,
                  amount: 0,
                  currency: 'usd',
                  description: "Some line item name for #{identifier} (100 B)"
                }
              ).and_return([OpenStruct.new(id: 1)])
              expect(invoice).to receive(:send_invoice).and_return(OpenStruct.new(id: 1))

              expect(invoicer.create_invoice).to eq(OpenStruct.new(id: 1))
            end
          end
        end

        context 'with total grater than 0' do
          before do
            allow_any_instance_of(ResourceFeeCalculatorService).to receive(:calculate).and_return(
              { storage_fee: 150, storage_fee_label: 'Some line item name', invoice_fee: 199, total: 150 }
            )
          end

          it 'returns true' do
            invoice = OpenStruct.new(id: 1, send_invoice: OpenStruct.new(id: 1))
            expect(Stripe::Invoice).to receive(:create).with(
              {
                auto_advance: true,
                collection_method: 'send_invoice',
                customer: 'stripe_customer_id',
                days_until_due: 30,
                description: "Dryad deposit #{identifier}, #{resource.title}"
              }
            ).and_return(invoice)
            expect(Stripe::InvoiceItem).to receive(:create).with(
              {
                customer: 'stripe_customer_id',
                invoice: 1,
                amount: 15_000,
                currency: 'usd',
                description: "Some line item name for #{identifier} (100 B)"
              }
            ).and_return([OpenStruct.new(id: 1)])
            expect(Stripe::InvoiceItem).to receive(:create).with(
              {
                customer: 'stripe_customer_id',
                invoice: 1,
                amount: 19_900,
                currency: 'usd',
                description: 'Invoice fee'
              }
            ).and_return([OpenStruct.new(id: 2)])
            expect(invoice).to receive(:send_invoice).and_return(OpenStruct.new(id: 1))

            expect(invoicer.create_invoice).to eq(OpenStruct.new(id: 1))
          end

          it 'saves customer id on author' do
            expect(author.reload.stripe_customer_id).to be_nil
            invoicer.create_invoice
            expect(author.reload.stripe_customer_id).to eq('stripe_customer_id')
          end

          it 'updates payment information on identifier' do
            expect(identifier.reload.payment_id).to be_nil
            invoicer.create_invoice
            identifier.reload
            expect(identifier.payment_id).not_to be_nil
            expect(identifier.payment_type).to eq('stripe')
            expect(identifier.last_invoiced_file_size).to eq(100)
          end
        end

        describe '#handle_customer' do
          let(:invoice_details) do
            {
              'author_id' => author.id,
              'customer_name' => 'Customer Name',
              'customer_email' => 'customer.email@example.com'
            }
          end

          before { allow(invoicer).to receive(:lookup_prior_stripe_customer_id).and_return('stripe_customer_id') }

          context 'when author already has the customer_id' do
            before { author.update!(stripe_customer_id: 'some-id') }

            it 'the value gets updated' do
              expect do
                invoicer.handle_customer(invoice_details)
              end.to change {
                author.reload.stripe_customer_id
              }.from('some-id').to('stripe_customer_id')
            end
          end

          context 'when author has no customer_id' do
            before { author.update!(stripe_customer_id: nil) }

            it 'sets a customer id value' do
              expect do
                invoicer.handle_customer(invoice_details)
              end.to change {
                author.reload.stripe_customer_id
              }.from(nil).to('stripe_customer_id')
            end
          end
        end
      end
    end
  end
end
