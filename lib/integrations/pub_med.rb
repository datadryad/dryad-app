module Integrations
  class PubMed < Integrations::Base
    # Example: https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=40959162&retmode=xml
    BASE_URL = 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi'.freeze
    DB       = 'pubmed'.freeze
    # Example: https://pmc.ncbi.nlm.nih.gov/tools/idconv/api/v1/articles/?tool=my_tool&ids=10.1007/s11249-025-02049-1
    PMC_BASE_URL = 'https://pmc.ncbi.nlm.nih.gov/tools/idconv/api/v1/articles/'.freeze

    def fetch_awards_by_id(pubmed_id)
      response = get_xml(BASE_URL, { id: pubmed_id, db: DB, retmode: 'xml' })
      grants = response.at_xpath('//PubmedArticleSet/PubmedArticle/MedlineCitation/Article/GrantList').children
      grants.map do |grant|
        grant.at_xpath('GrantID').text
      end.compact
    rescue StandardError
      []
    end

    def pmid_by_primary_article(article_id)
      response = get_xml(PMC_BASE_URL, { ids: article_id, tool: 'my_tool' })
      response.at_xpath('//pmcids/record')['pmid']
    rescue StandardError
      nil
    end
  end
end
