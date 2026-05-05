module Integrations
  class PubMed < Integrations::Base
    def esearch(term:, database: 'pubmed', retmode: 'json')
      url = 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?'
      query = { term: term, db: database, retmode: retmode }
      return get_json(url, query) if retmode == 'json'

      get_xml(url, query) if retmode == 'xml'
    end

    # Example: https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=40959162
    def efetch(id:, database: 'pubmed', retmode: 'xml')
      url = 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi'
      query = { id: id, db: database, retmode: retmode }
      return get_xml(url, query) if retmode == 'xml'

      get_json(url, query) if retmode == 'json'
    end

    # Example: https://pmc.ncbi.nlm.nih.gov/tools/idconv/api/v1/articles/?tool=my_tool&ids=10.1007/s11249-025-02049-1
    def id_converter(id:, type:)
      url = 'https://pmc.ncbi.nlm.nih.gov/tools/idconv/api/v1/articles/'
      get_json(url, { ids: id, idtype: type, format: 'json', tool: 'dryad', email: APP_CONFIG['submission_error_email'] })
    rescue StandardError
      nil
    end

    def fetch_awards_by_id(pubmed_id)
      response = efetch(id: pubmed_id)
      grants = response.at_xpath('//PubmedArticleSet/PubmedArticle/MedlineCitation/Article/GrantList').children
      grants.map do |grant|
        grant.at_xpath('GrantID').text
      end.compact
    rescue StandardError
      []
    end

    def doi_by_pmid(pmid)
      response = id_converter(id: pmid, type: 'pmid')
      response.dig('records', 0, 'doi')
    end

    def pmid_by_doi(doi)
      response = id_converter(id: doi, type: 'doi')
      response.dig('records', 0, 'pmid')
    end
  end
end
