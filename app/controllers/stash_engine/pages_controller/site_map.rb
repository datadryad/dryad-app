require 'nokogiri'
module StashEngine
  class PagesController
    class SiteMap
      include Rails.application.routes.url_helpers

      attr_accessor :page_size

      def initialize
        # really all we need to select is identifier_id, identifier, resource_id and resource.updated_at for sitemap

        # @identifiers = StashEngine::Identifier.where(pub_state: %w[embargoed published])
        #                   .order('stash_engine_identifiers.id')

        subquery = <<-SQL
          SELECT max(stash_engine_resources.id) as res_id, identifier_id
		      FROM stash_engine_resources
          WHERE identifier_id IS NOT NULL AND meta_view = 1
          GROUP BY identifier_id
        SQL

        # the select part of the query is deferred to specific query because count causes badness when it
        # tries to count a series of fields
        @datasets = StashEngine::Identifier \
          .joins("INNER JOIN (#{subquery}) as res2 ON stash_engine_identifiers.id = res2.identifier_id")
          .joins('INNER JOIN stash_engine_resources res ON res.id = res2.res_id')
          .where("stash_engine_identifiers.pub_state IN ('embargoed', 'published')")
          .order('stash_engine_identifiers.id')

        @page_size = 1000
      end

      def count
        @datasets.select('stash_engine_identifiers.id').count
      end

      def pages
        return 0 if count == 0

        ((count - 1) / @page_size) + 1
      end

      def page(number)
        number = number.to_i
        number = 1 if number < 1
        @datasets.select('stash_engine_identifiers.id as identifier_id, stash_engine_identifiers.identifier, ' \
                         'res.id as resource_id, res.updated_at').limit(@page_size).offset(@page_size * (number - 1))
      end

      def sitemap_index
        builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
          xml.sitemapindex('xmlns' => 'http://www.sitemaps.org/schemas/sitemap/0.9') do
            1.upto(pages) do |i|
              xml.sitemap do
                xml.loc sitemap_url(format: 'xml', page: i)
                xml.lastmod Time.now.utc.iso8601
              end
            end
          end
        end
        builder.to_xml
      end

      def sitemap_page(page_number)
        datasets = page(page_number)
        builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
          xml.urlset('xmlns' => 'http://www.sitemaps.org/schemas/sitemap/0.9') do
            datasets.each do |i|
              xml.url do
                xml.loc Rails.application.routes.url_helpers.show_url("doi:#{i.identifier}")
                xml.lastmod i.updated_at.utc.iso8601
                # changefreq and crawling priority are not really known
              end
            end
          end
        end
        builder.to_xml
      end
      # stash_identifier.resources.where(meta_view: true).order('id DESC').first
    end
  end
end
