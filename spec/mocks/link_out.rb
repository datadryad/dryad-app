module Mocks

  module LinkOut

    def mock_link_out!(doi = nil, pmid = nil)
      stub_pubmed_lookup(doi: doi)
      stub_pubmed_sequence_lookup(pmid: pmid)
    end

    # rubocop:disable Metrics/MethodLength
    def stub_pubmed_lookup(doi: Faker::Pid.doi)
      # Mock a request for a specific DOI
      stub_request(:get, %r{eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi})
        .with(headers: {'Accept' => 'text/xml'})
        .to_return(status: 200, body: pubmed_response(doi), headers: { 'Content-Type' => 'text/xml' })
    end

    def stub_pubmed_sequence_lookup(pmid: Faker::Number.number(5))
      stub_request(:get, %r{www.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi?})
        .with(headers: { 'Accept' => 'text/xml' })
        .to_return(status: 200, body: sequence_response(pmid), headers: { 'Content-Type' => 'text/xml' })
    end

    private

    def pubmed_response(doi)
      <<~XML
        <?xml version="1.0" encoding="UTF-8" ?>
        <!DOCTYPE eSearchResult PUBLIC "-//NLM//DTD esearch 20060628//EN" "https://eutils.ncbi.nlm.nih.gov/eutils/dtd/20060628/esearch.dtd">
        <eSearchResult>
          <Count>1</Count>
          <RetMax>1</RetMax>
          <RetStart>0</RetStart>
          <IdList>
            <Id>#{Faker::Number.number(6)}</Id>
          </IdList>
          <TranslationSet/>
          <TranslationStack>
            <TermSet>
              <Term>#{doi}[doi]</Term>
              <Field>doi</Field>
              <Count>1</Count>
              <Explode>N</Explode>
            </TermSet>
            <OP>GROUP</OP>
          </TranslationStack>
          <QueryTranslation>#{doi}[doi]</QueryTranslation>
        </eSearchResult>
      XML
    end

    def sequence_response(pmid)
      <<~XML
        <?xml version="1.0" encoding="UTF-8" ?>
        <!DOCTYPE eSearchResult PUBLIC "-//NLM//DTD esearch 20060628//EN" "https://eutils.ncbi.nlm.nih.gov/eutils/dtd/20060628/esearch.dtd">
        <eLinkResult>
          <LinkSet>
            <DbFrom>pubmed</DbFrom>
            <IdList>
              <Id>#{pmid}</Id>
            </IdList>
            <LinkSetDb>
              <DbTo>nuccore</DbTo>
              <LinkName>pubmed_nuccore</LinkName>
              <Link>
                <Id>#{Faker::Number.number(9)}</Id>
              </Link>
              <Link>
                <Id>#{Faker::Number.number(9)}</Id>
              </Link>
            </LinkSetDb>
          </LinkSet>
        </eLinkResult>
      XML
    end

  end

end
