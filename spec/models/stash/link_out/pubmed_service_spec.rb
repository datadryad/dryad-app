require 'ostruct'
require 'byebug'
require 'stash/link_out/pubmed_service'

module Stash
  module LinkOut

    TEST_FILE_DIR = "#{Dir.pwd}/spec/tmp/link_out".freeze

    RESPONSE = <<~XML.freeze
      <?xml version="1.0" encoding="UTF-8" ?>
      <!DOCTYPE eSearchResult PUBLIC "-//NLM//DTD esearch 20060628//EN" "https://eutils.ncbi.nlm.nih.gov/eutils/dtd/20060628/esearch.dtd">
      <eSearchResult>
        <Count>1</Count>
        <RetMax>1</RetMax>
        <RetStart>0</RetStart>
        <IdList>
          <Id>26028437</Id>
        </IdList>
        <TranslationSet/>
        <TranslationStack>
          <TermSet>
            <Term>10.1016/j.cub.2015.04.062[doi]</Term>
            <Field>doi</Field>
            <Count>1</Count>
            <Explode>N</Explode>
          </TermSet>
          <OP>GROUP</OP>
        </TranslationStack>
        <QueryTranslation>10.1016/j.cub.2015.04.062[doi]</QueryTranslation>
      </eSearchResult>
    XML

    EMPTY_RESPONSE = <<~XML.freeze
      <?xml version="1.0" encoding="UTF-8" ?>
      <!DOCTYPE eSearchResult PUBLIC "-//NLM//DTD esearch 20060628//EN" "https://eutils.ncbi.nlm.nih.gov/eutils/dtd/20060628/esearch.dtd">
      <eSearchResult>
        <Count>0</Count>
        <RetMax>0</RetMax>
        <RetStart>0</RetStart>
        <IdList/>
        <TranslationSet/>
        <TranslationStack>
          <TermSet>
            <Term>10.1016/j.cub.2015.04.062[doi]</Term>
            <Field>doi</Field>
            <Count>1</Count>
            <Explode>N</Explode>
          </TermSet>
          <OP>GROUP</OP>
        </TranslationStack>
        <QueryTranslation>10.1016/j.cub.2015.04.062[doi]</QueryTranslation>
      </eSearchResult>
    XML

    describe PubmedService do
      before(:each) do
        # Mock the app_config.yml and Rails.application.routes since we're not loading the full
        # Rails stack
        link_out = OpenStruct.new(APP_CONFIG.link_out)
        allow(APP_CONFIG).to receive(:link_out).and_return(link_out)
        allow(link_out).to receive(:pubmed).and_return(OpenStruct.new(link_out.pubmed))
        allow(Rails).to receive(:application).and_return(
          OpenStruct.new(routes: OpenStruct.new(url_helpers: OpenStruct.new(root_url: 'example.org')))
        )

        stub_request(:get, %r{eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?})
          .with(headers: { 'Accept' => 'text/xml' })
          .to_return(status: 200, body: RESPONSE.to_s, headers: {})

        @svc = LinkOut::PubmedService.new
      end

      describe '#lookup_pubmed_id' do
        it 'returns a nil if the API did not find a Pubmed ID' do
          stub_request(:get, %r{eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?})
            .with(headers: { 'Accept' => 'text/xml' })
            .to_return(status: 200, body: EMPTY_RESPONSE.to_s, headers: {})

          expect(@svc.lookup_pubmed_id('abcd')).to eql(nil)
        end
        it 'returns the Pubmed ID if the API found a match' do
          expect(@svc.lookup_pubmed_id('abcd')).to eql('26028437')
        end
      end
    end
  end
end
