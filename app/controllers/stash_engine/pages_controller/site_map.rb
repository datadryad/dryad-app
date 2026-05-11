require 'nokogiri'
module StashEngine
  class PagesController
    class SiteMap
      include Rails.application.routes.url_helpers

      PER_PAGE = 1000

      def sitemap_index
        results = Rails.cache.fetch('sitemap_index', expires_in: 1.day) do
          service = StashApi::SolrSearchService.new(query: '*', filters: { sort: 'date desc' })
          result = service.search(fields: 'dc_identifier_s updated_at_dt')
          result['response']
        end

        @count = results['numFound']
        builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
          xml.sitemapindex('xmlns' => 'http://www.sitemaps.org/schemas/sitemap/0.9') do
            1.upto(pages) do |i|
              xml.sitemap do
                xml.loc sitemap_url(format: 'xml', page: i)
                xml.lastmod results.dig('docs', 0, 'updated_at_dt')
              end
            end
          end
        end
        builder.to_xml
      end

      def pages
        return 0 if @count == 0

        ((@count - 1) / PER_PAGE) + 1
      end

      def sitemap_page(page)
        results = Rails.cache.fetch("sitemap_page_#{page}", expires_in: 1.day) do
          service = StashApi::SolrSearchService.new(query: '*', filters: { sort: 'date asc' })
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
    end
  end
end
