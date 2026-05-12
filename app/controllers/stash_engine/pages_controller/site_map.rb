require 'nokogiri'
module StashEngine
  class PagesController
    class SiteMap
      include Rails.application.routes.url_helpers

      PER_PAGE = 1000

      def sitemap_index
        results = Rails.cache.fetch('sitemap_index', expires_in: 1.day) do
          service = StashApi::SolrSearchService.new(query: '*', filters: { sort: 'updated_at_dt desc' })
          result = service.search(fields: 'dc_identifier_s updated_at_dt')
          result['response']
        end

        @count = results['numFound']
        builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
          xml.sitemapindex('xmlns' => 'http://www.sitemaps.org/schemas/sitemap/0.9') do
            xml.sitemap do
              xml.loc sitemap_url(format: 'xml', page: 0)
              xml.lastmod deploy_date
            end
            1.upto(pages) do |i|
              xml.sitemap do
                xml.loc sitemap_url(format: 'xml', page: i)
                xml.lastmod i == pages ? results.dig('docs', 0, 'updated_at_dt') : deploy_date
              end
            end
          end
        end
        builder.to_xml
      end

      def deploy_date
        DateTime.parse(Rails.application.config.assets.version).iso8601
      end

      def pages
        return 0 if @count == 0

        ((@count - 1) / PER_PAGE) + 1
      end

      def sitemap_page(page)
        results = Rails.cache.fetch("sitemap_page_#{page}", expires_in: 1.day) do
          service = StashApi::SolrSearchService.new(query: '*', filters: { sort: 'updated_at_dt asc' })
          result = service.search(page: page, per_page: PER_PAGE, fields: 'dc_identifier_s updated_at_dt')
          result['response']['docs']
        end

        builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
          xml.urlset('xmlns' => 'http://www.sitemaps.org/schemas/sitemap/0.9') do
            results.each do |id|
              xml.url do
                xml.loc Rails.application.routes.url_helpers.show_url(id['dc_identifier_s'])
                xml.lastmod id['updated_at_dt']
              end
            end
          end
        end
        builder.to_xml
      end

      def sitemap_static
        public_pages = [
          about_url, mission_url, join_us_url, publishers_url, institutions_url, support_us_url, code_of_conduct_url,
          ethics_url, terms_url, partner_terms_url, definitions_url, publication_policy_url, privacy_url, accessibility_url,
          choose_login_url, contact_url, journals_url, api_url, help_url
        ]
        builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
          xml.urlset('xmlns' => 'http://www.sitemaps.org/schemas/sitemap/0.9') do
            public_pages.each do |url|
              xml.url do
                xml.loc url
                xml.lastmod deploy_date
              end
            end
            HELP_PAGES.each do |page|
              xml.url do
                xml.loc "#{ROOT_URL}#{page[:path]}"
                xml.lastmod deploy_date
              end
            end
          end
        end
        builder.to_xml
      end
    end
  end
end
