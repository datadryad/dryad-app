require 'ostruct'
require 'spec_helper'
require_relative '../../../../lib/stash/payments/invoicer'

module Stash
  module Payments
    describe Invoicer do

      before(:each) do
        @identifier = double(StashEngine::Identifier)
        allow(@identifier).to receive(:to_s).and_return('doi:10.123/a1b.c2d3')
        allow(@identifier).to receive(:invoice_id=)
        allow(@identifier).to receive(:save).and_return(true)

        @resource_id = 17
        @resource = double(StashEngine::Resource)
        allow(StashEngine::Resource).to receive(:find).with(@resource_id).and_return(@resource)
        allow(@resource).to receive(:authors).and_return([@author])
        allow(@resource).to receive(:id).and_return(@resource_id)
        allow(@resource).to receive(:title).and_return('My Test Dataset')
        allow(@resource).to receive(:identifier).and_return(@identifier)

        @author = double(StashEngine::Author)
        allow(StashEngine::Author).to receive(:primary).with(@resource_id).and_return(@author)
        allow(StashEngine::Author).to receive(:where).and_return(nil)
        allow(@author).to receive(:update).and_return(true)
        allow(@author).to receive(:id).and_return(9)
        allow(@author).to receive(:author_email).and_return('jane.doe@example.org')
        allow(@author).to receive(:author_standard_name).and_return('Jane Doe')

        @cust_id = '9999'
        fake_invoice_item = OpenStruct.new(customer: @cust_id, amount: '99.99', currency: 'usd', description: 'Data Processing Charge')
        fake_invoice = OpenStruct.new(customer: @cust_id, description: 'Dryad deposit',
                                      metadata: { curator: 'The Curator' }, finalize_invoice: 'STRIPE1234')
        fake_customer = OpenStruct.new(id: @cust_id, email: @author.author_email, description: @author.author_standard_name)

        @invoicer = Invoicer.new(resource: @resource, curator: @curator)
        allow(@invoicer).to receive(:set_api_key).and_return(true)
        allow(@invoicer).to receive(:create_invoice_item_for_dpc).and_return(fake_invoice_item)
        allow(@invoicer).to receive(:create_invoice).and_return(fake_invoice)
        allow(@invoicer).to receive(:create_customer).and_return(fake_customer)
        allow(@invoicer).to receive(:lookup_prior_stripe_customer_id).and_return(nil)
      end

      it 'creates an invoice for a new stripe customer' do
        expect(@invoicer.charge_user_via_invoice).to eql('STRIPE1234')
      end

      it 'creates an invoice for an existing stripe customer' do
        allow(@invoicer).to receive(:lookup_prior_stripe_customer_id).and_return('999911')
        expect(@invoicer.charge_user_via_invoice).to eql('STRIPE1234')
      end

      it 'does not create an invoice when the resource has no primary author' do
        allow(StashEngine::Author).to receive(:primary).with(@resource_id).and_return(nil)
        expect(@invoicer.charge_user_via_invoice).to eql(nil)
      end

    end
  end
end
