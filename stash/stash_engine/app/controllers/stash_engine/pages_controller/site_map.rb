require 'nokogiri'
module StashEngine
  class PagesController
    class SiteMap
      include Rails.application.routes.url_helpers

      def initialize
        @identifiers = StashEngine::Identifier.joins(:resources).where(pub_state: %w[embargoed published])
                           .order('stash_engine_identifiers.id').distinct
        @page_size = 1000
      end

      def count
        @identifiers.count
      end

      def pages
        return 0 if count == 0
        (count - 1) / @page_size + 1
      end

      def page(number)
        number = number.to_i
        number = 1 if number < 1
        @identifiers.limit(@page_size).offset(@page_size * (number - 1))
      end

      def sitemap_index
        fun = <<-HTML.chomp
        <?xml version="1.0" encoding="UTF-8"?>
        <sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
          <sitemap>
            <loc>https://dspace.mit.edu/sitemap?map=0</loc>
            <lastmod>2020-10-15T02:03:53Z</lastmod>
          </sitemap>
          <sitemap>
            <loc>https://dspace.mit.edu/sitemap?map=1</loc>
            <lastmod>2020-10-15T02:03:53Z</lastmod>
          </sitemap>
          <sitemap>
            <loc>https://dspace.mit.edu/sitemap?map=2</loc>
            <lastmod>2020-10-15T02:03:53Z</lastmod>
          </sitemap>
        </sitemapindex>
        HTML

        builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
          xml.sitemapindex('xmlns' => 'http://www.sitemaps.org/schemas/sitemap/0.9') {
            1.upto(pages) do |i|
              xml.sitemap {
                xml.loc sitemap_url(format: 'xml', page: i)
                xml.lastmod Time.now.utc.iso8601
              }
            end
          }
        end
        builder.to_xml
      end
      # stash_identifier.resources.where(meta_view: true).order('id DESC').first
    end
  end
end