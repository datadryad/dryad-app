require 'spec_helper'

module Stash
  module Sword
    describe DepositReceipt do
      describe '#parse_xml' do

        it 'parses the response from the spec' do
          xml = File.read('spec/data/deposit_receipt_spec.xml')
          receipt = DepositReceipt.parse_xml(xml)
          expect(receipt).to be_a(DepositReceipt)

          em_iri = receipt.link(rel: 'edit-media')
          expect(em_iri.href).to eq(URI('http://www.swordserver.ac.uk/col1/mydeposit'))

          se_iri = receipt.link(rel: URI('http://purl.org/net/sword/terms/add'))
          expect(se_iri.href).to eq(URI('http://www.swordserver.ac.uk/col1/mydeposit.atom'))

          expect(receipt.em_iri).to eq(em_iri.href)
          expect(receipt.se_iri).to eq(se_iri.href)
        end

        it 'parses a Merritt response' do
          xml = File.read('spec/data/deposit_receipt_merritt.xml')
          receipt = DepositReceipt.parse_xml(xml)
          expect(receipt).to be_a(DepositReceipt)

          em_iri = receipt.link(rel: 'edit-media')
          expect(em_iri.href).to eq(URI('http://merritt-dev.cdlib.org/d/ark%3A%2F99999%2Ffk4ht2vf09'))

          se_iri = receipt.link(rel: URI('http://purl.org/net/sword/terms/add'))
          expect(se_iri.href).to eq(URI('http://merritt-dev.cdlib.org/sword/v2/object/doi:10.20200/hij1000106'))

          expect(receipt.em_iri).to eq(em_iri.href)
          expect(receipt.se_iri).to eq(se_iri.href)
        end
      end
    end
  end
end
