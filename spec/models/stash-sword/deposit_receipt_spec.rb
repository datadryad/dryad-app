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

          edit_iri = receipt.link(rel: 'edit')
          expect(edit_iri.href).to eq(URI('http://www.swordserver.ac.uk/col1/mydeposit.atom'))

          expect(receipt.em_iri).to eq(em_iri.href)
          expect(receipt.se_iri).to eq(se_iri.href)
          expect(receipt.edit_iri).to eq(edit_iri.href)
        end

        it 'parses a Merritt response' do
          xml = File.read('spec/data/deposit_receipt_merritt.xml')
          receipt = DepositReceipt.parse_xml(xml)
          expect(receipt).to be_a(DepositReceipt)

          em_iri = receipt.link(rel: 'edit-media')
          expect(em_iri.href).to eq(URI('http://merritt-dev.cdlib.org/d/ark%3A%2F99999%2Ffk47h1tz4k'))

          se_iri = receipt.link(rel: URI('http://purl.org/net/sword/terms/add'))
          expect(se_iri.href).to eq(URI('http://sword-aws-dev.cdlib.org:39001/mrtsword/edit/dash_cdl/doi%3A10.5072%2FFK1465406644'))

          edit_iri = receipt.link(rel: 'edit')
          expect(edit_iri.href).to eq(URI('http://sword-aws-dev.cdlib.org:39001/mrtsword/edit/dash_cdl/doi%3A10.5072%2FFK1465406644'))

          expect(receipt.em_iri).to eq(em_iri.href)
          expect(receipt.se_iri).to eq(se_iri.href)
          expect(receipt.edit_iri).to eq(edit_iri.href)
        end
      end
    end
  end
end
