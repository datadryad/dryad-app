require 'ostruct'
require 'action_controller'

module Stash
  module Payments
    describe Invoicer do
      include Mocks::Salesforce
      before do
        mock_salesforce!
      end

      describe 'general behavior' do
        before do
          @identifier = double(StashEngine::Identifier)
          allow(@identifier).to receive(:to_s).and_return('doi:10.123/a1b.c2d3')
          allow(@identifier).to receive(:payment_type)
          allow(@identifier).to receive(:payment_id=)
          allow(@identifier).to receive(:payment_type=)
          allow(@identifier).to receive(:save).and_return(true)
          allow(@identifier).to receive(:created_at).and_return(Time.now)

          @resource_id = 17
          @resource = double(StashEngine::Resource)
          allow(StashEngine::Resource).to receive(:find).with(@resource_id).and_return(@resource)
          allow(@resource).to receive(:authors).and_return([@author])
          allow(@resource).to receive(:id).and_return(@resource_id)
          allow(@resource).to receive(:title).and_return('My Test Dataset')
          allow(@resource).to receive(:identifier).and_return(@identifier)

          @author = double(StashEngine::Author)
          allow(StashEngine::Author).to receive(:where).and_return(nil)
          allow(@author).to receive(:update).and_return(true)
          allow(@author).to receive(:id).and_return(9)
          allow(@author).to receive(:author_email).and_return('jane.doe@example.org')
          allow(@author).to receive(:author_standard_name).and_return('Jane Doe')
          allow(@author).to receive(:stripe_customer_id).and_return(nil)
          allow(@resource).to receive(:owner_author).and_return(@author)

          @cust_id = '9999'
          fake_invoice_item = OpenStruct.new(customer: @cust_id, amount: '99.99', currency: 'usd', description: 'Data Processing Charge')
          fake_invoice = OpenStruct.new(customer: @cust_id, description: 'Dryad deposit',
                                        metadata: { curator: 'The Curator' }, send_invoice: 'STRIPE1234')
          fake_customer = OpenStruct.new(id: @cust_id, email: @author.author_email, description: @author.author_standard_name)

          @invoicer = Invoicer.new(resource: @resource, curator: @curator)
          allow(@invoicer).to receive(:create_invoice_items_for_dpc).and_return([fake_invoice_item])
          allow(@invoicer).to receive(:create_invoice).and_return(fake_invoice)
          allow(@invoicer).to receive(:create_customer).and_return(fake_customer)
          allow(@invoicer).to receive(:lookup_prior_stripe_customer_id).and_return(nil)
          allow(@invoicer).to receive(:ds_size).and_return(5.01e+10.to_i)

          allow(Stripe::InvoiceItem).to receive(:create) { |hsh| hsh }
        end

        it 'creates an invoice for a new stripe customer' do
          expect(@invoicer.charge_user_via_invoice).to eql('STRIPE1234')
        end

        it 'creates an invoice for an existing stripe customer' do
          allow(@invoicer).to receive(:lookup_prior_stripe_customer_id).and_return('999911')
          allow(@author).to receive(:stripe_customer_id).and_return('999911')
          expect(@invoicer.charge_user_via_invoice).to eql('STRIPE1234')
        end

        it 'does not create an invoice when the resource has no primary author' do
          allow(@resource).to receive(:owner_author).and_return(nil)
          expect(@invoicer.charge_user_via_invoice).to eql(nil)
        end

        it 'gets the dataset size' do
          expect(@invoicer.ds_size).to eq(50_100_000_000)
        end

        it 'calculates overage bytes' do
          expect(@invoicer.overage_bytes).to eq(100_000_000)
        end

        it 'calculates overage chunks' do
          expect(@invoicer.overage_chunks(@invoicer.overage_bytes)).to eq(1)
        end

        it 'makes an overage message' do
          expect(@invoicer.overage_message(@invoicer.overage_bytes))
            .to eq('Oversize submission charges for doi:10.123/a1b.c2d3. Overage amount is 100 MB ' \
                   '@ $50.00 per 10 GB or part thereof over 50 GB (see ' \
                   'https://datadryad.org/publishing_charges for details)')
        end

        it 'defaults to the main fee when there is no cutoff date' do
          allow(APP_CONFIG.payments).to receive(:dpc_change_date).and_return(nil)
          expect(Stash::Payments::Invoicer.data_processing_charge(identifier: @identifier)).to be(APP_CONFIG.payments.data_processing_charge)
        end

        it 'gives the old price for datasets created prior to the cutoff date' do
          allow(APP_CONFIG.payments).to receive(:dpc_change_date).and_return(Date.tomorrow)
          expect(Stash::Payments::Invoicer.data_processing_charge(identifier: @identifier)).to be(APP_CONFIG.payments.data_processing_charge)
        end

        it 'gives the new price for datasets created after the cutoff date' do
          allow(APP_CONFIG.payments).to receive(:dpc_change_date).and_return(Date.yesterday)
          expect(Stash::Payments::Invoicer.data_processing_charge(identifier: @identifier)).to be(APP_CONFIG.payments.data_processing_charge_new)
        end
      end

      describe 'invoice charges' do
        let(:identifier) { create(:identifier, payment_type: 'stripe', payment_id: 'stripe-123') }
        let(:res_1) { create(:resource, identifier: identifier, total_file_size: 103_807_000_000, created_at: 1.minute.ago) }
        let(:res_2) { create(:resource, identifier: identifier, total_file_size: new_res_file_size) }
        let(:new_res_file_size) { 103_807_000_000 }
        let(:curator) { create(:user, role: 'curator') }
        subject { described_class.new(resource: res_1, curator: curator) }

        before do
          allow_any_instance_of(described_class).to receive(:stripe_user_customer_id).and_return('stripe_customer_id')
        end

        context 'on first publish' do
          context 'without oversize files' do
            let(:res_1) { create(:resource, identifier: identifier, total_file_size: 49_807_000_000) }

            it 'invoices only processing' do
              expect(Stripe::Invoice).to receive(:create).with(
                {
                  auto_advance: true,
                  collection_method: 'send_invoice',
                  customer: 'stripe_customer_id',
                  days_until_due: 30,
                  description: "Dryad deposit #{res_1.identifier}, #{res_1.title}",
                  metadata: { 'curator' => curator&.name }
                }
              ).and_return(OpenStruct.new(id: 1))

              expect(Stripe::InvoiceItem).to receive(:create).with(
                {
                  amount: 15_000,
                  customer: 'stripe_customer_id',
                  invoice: 1,
                  currency: 'usd',
                  description: "Data processing charge for #{identifier} (49.81 GB)"
                }
              ).and_return([OpenStruct.new(id: 1)])

              expect { subject.charge_user_via_invoice }.not_to(change do
                identifier.reload.last_invoiced_file_size
              end)
            end
          end

          context 'with oversize files' do
            it 'invoices for processing and oversize' do
              expect(Stripe::Invoice).to receive(:create).with(
                {
                  auto_advance: true,
                  collection_method: 'send_invoice',
                  customer: 'stripe_customer_id',
                  days_until_due: 30,
                  description: "Dryad deposit #{res_1.identifier}, #{res_1.title}",
                  metadata: { 'curator' => curator&.name }
                }
              ).and_return(OpenStruct.new(id: 1))

              expect(Stripe::InvoiceItem).to receive(:create).with(
                {
                  amount: 15_000,
                  customer: 'stripe_customer_id',
                  invoice: 1,
                  currency: 'usd',
                  description: "Data processing charge for #{identifier} (103.81 GB)"
                }
              ).and_return([OpenStruct.new(id: 1)])
              expect(Stripe::InvoiceItem).to receive(:create).with(
                {
                  customer: 'stripe_customer_id',
                  invoice: 1,
                  currency: 'usd',
                  unit_amount: APP_CONFIG.payments.additional_storage_chunk_cost,
                  quantity: 6,
                  description: <<~TEXT.squish
                    Oversize submission charges for #{identifier}. Overage amount is 53.81 GB @ $50.00
                    per 10 GB or part thereof over 50 GB (see https://datadryad.org/publishing_charges for details)
                  TEXT
                }
              ).and_return([OpenStruct.new(id: 2)])

              expect { subject.charge_user_via_invoice }.to change {
                identifier.reload.last_invoiced_file_size
              }.from(nil).to(res_1.total_file_size)
            end
          end
        end

        context 'on second publish' do
          let(:identifier) { create(:identifier, payment_type: 'stripe', payment_id: 'stripe-123', last_invoiced_file_size: 103_807_000_000) }
          subject { described_class.new(resource: res_2, curator: curator) }

          context 'if file size did not change' do
            it 'does not bill for overage' do
              expect { subject.check_new_overages(103_807_000_000) }.not_to(change do
                identifier.reload.last_invoiced_file_size
              end)
            end
          end

          context 'if file size decreases' do
            let(:new_res_file_size) { 83_807_000_000 }

            it 'does not bill for overage' do
              expect { subject.check_new_overages(103_807_000_000) }.not_to(change do
                identifier.reload.last_invoiced_file_size
              end)
            end
          end

          context 'if charges changed but they go over 10GB limit' do
            let(:new_res_file_size) { 109_807_000_000 }

            it 'does not bill for overage' do
              subject.check_new_overages(103_807_000_000)
              expect { subject.check_new_overages(103_807_000_000) }.not_to(change do
                identifier.reload.last_invoiced_file_size
              end)
            end
          end

          context 'if charges changed and they go over 10GB limit' do
            let(:new_res_file_size) { 129_807_000_000 }

            it 'does bill only for overage' do
              expect(Stripe::Invoice).to receive(:create).with(
                {
                  auto_advance: true,
                  collection_method: 'send_invoice',
                  customer: 'stripe_customer_id',
                  days_until_due: 30,
                  description: "Dryad deposit #{res_2.identifier}, #{res_2.title}",
                  metadata: { 'curator' => curator&.name }
                }
              ).and_return(OpenStruct.new(id: 2))

              expect(Stripe::InvoiceItem).to receive(:create).with(
                {
                  customer: 'stripe_customer_id',
                  invoice: 2,
                  currency: 'usd',
                  unit_amount: APP_CONFIG.payments.additional_storage_chunk_cost,
                  quantity: 3,
                  description: <<~TEXT.squish
                    Oversize submission charges for #{identifier}. Overage amount is 26 GB @ $50.00
                    per 10 GB or part thereof over 50 GB (see https://datadryad.org/publishing_charges for details)
                  TEXT
                }
              ).and_return([OpenStruct.new(id: 2)])

              expect { subject.check_new_overages(103_807_000_000) }.to change {
                identifier.reload.last_invoiced_file_size
              }.from(103_807_000_000).to(129_807_000_000)
            end
          end
        end
      end
    end
  end
end
