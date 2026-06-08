module Integrations
  class PubMed < Integrations::Base
    # https://www.ncbi.nlm.nih.gov/home/develop/api/
    # https://www.ncbi.nlm.nih.gov/books/NBK25499/
    API_KEY = APP_CONFIG.link_out.pubmed.api_key

    def esearch(term:, database: 'pubmed', retmode: 'json')
      url = 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi'
      query = { term: term, db: database, retmode: retmode, api_key: API_KEY }
      return get_json(url, query) if retmode == 'json'

      get_xml(url, query) if retmode == 'xml'
    end

    def efetch(id:, database: 'pubmed', retmode: 'xml')
      url = 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi'
      query = { id: id, db: database, retmode: retmode, api_key: API_KEY }
      return get_xml(url, query) if retmode == 'xml'

      get_json(url, query) if retmode == 'json'
    end

    def elink(id:, database:, dbfrom: 'pubmed')
      url = 'https://www.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi'
      query = { id: id, db: database, dbfrom: dbfrom, api_key: API_KEY }

      get_xml(url, query)
    end

    # Only works if record is in PMC (free full text)
    def id_converter(id:, type:)
      url = 'https://pmc.ncbi.nlm.nih.gov/tools/idconv/api/v1/articles/'
      get_json(url, { ids: id, idtype: type, format: 'json', tool: 'dryad', email: APP_CONFIG['developer_email'] })
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

    def pmid_by_doi(doi)
      response = id_converter(id: doi, type: 'doi')
      response.dig('records', 0, 'pmid')&.to_s
    end

    # Use EFetch rather than IDConverter for more results
    def doi_by_pmid(pmid)
      response = efetch(id: pmid)
      response.at_xpath("//ELocationID[@EIdType='doi']")&.text
    end
  end
end
