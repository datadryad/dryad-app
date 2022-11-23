require 'ostruct'
require 'byebug'
require 'stash/link_out/pubmed_sequence_service'

module Stash
  module LinkOut
    describe PubmedSequenceService do

      before(:each) do
        @response = <<~XML.freeze
          <?xml version="1.0" encoding="UTF-8" ?>
          <!DOCTYPE eSearchResult PUBLIC "-//NLM//DTD esearch 20060628//EN" "https://eutils.ncbi.nlm.nih.gov/eutils/dtd/20060628/esearch.dtd">
          <eLinkResult>
            <LinkSet>
              <DbFrom>pubmed</DbFrom>
              <IdList>
                <Id>21166729</Id>
              </IdList>
              <LinkSetDb>
                <DbTo>nuccore</DbTo>
                <LinkName>pubmed_nuccore</LinkName>
                <Link>
                  <Id>316925971</Id>
                </Link>
                <Link>
                  <Id>316925605</Id>
                </Link>
              </LinkSetDb>
            </LinkSet>
          </eLinkResult>
        XML

        @empty_response = <<~XML.freeze
          <?xml version="1.0" encoding="UTF-8" ?>
          <!DOCTYPE eSearchResult PUBLIC "-//NLM//DTD esearch 20060628//EN" "https://eutils.ncbi.nlm.nih.gov/eutils/dtd/20060628/esearch.dtd">
          <eLinkResult>
            <LinkSet>
              <DbFrom>pubmed</DbFrom>
              <IdList>
                <Id>21166729</Id>
              </IdList>
            </LinkSet>
          </eLinkResult>
        XML

        # Mock the app_config.yml and Rails.application.routes since we're not loading the full
        # Rails stack
        link_out = OpenStruct.new(APP_CONFIG.link_out)
        allow(APP_CONFIG).to receive(:link_out).and_return(link_out)
        allow(link_out).to receive(:pubmed).and_return(OpenStruct.new(link_out.pubmed))
        allow(Rails).to receive(:application).and_return(
          OpenStruct.new(routes: OpenStruct.new(url_helpers: OpenStruct.new(root_url: 'example.org')))
        )

        stub_request(:get, %r{www.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi?})
          .with(headers: { 'Accept' => 'text/xml' })
          .to_return(status: 200, body: @response.to_s, headers: {})

        @svc = LinkOut::PubmedSequenceService.new
      end

      describe '#lookup_pubmed_id' do
        it 'returns a nil if the API did not find a Pubmed ID' do
          stub_request(:get, %r{www.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi?})
            .with(headers: { 'Accept' => 'text/xml' })
            .to_return(status: 200, body: @empty_response.to_s, headers: {})

          expect(@svc.lookup_genbank_sequences('21166729')).to eql({})
        end
        it 'returns the Pubmed ID if the API found a match' do
          results_hash = StashEngine::ExternalReference.sources.to_h { |db| [db, %w[316925971 316925605]] }
          expect(@svc.lookup_genbank_sequences('21166729')).to eql(results_hash)
        end
      end
    end
  end
end
