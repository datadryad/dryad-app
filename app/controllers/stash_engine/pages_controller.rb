module StashEngine
  class PagesController < ApplicationController
    # the homepage shows latest plans and other things, so more than a static page
    def home
      @dataset_count = Resource.submitted_dataset_count
      @hostname = request.host
    end

    # produces a sitemap for the domain name/tenant listing the released datasets
    # TODO: change page to display all that are embargoed or published, not merritt status and cache the doc so it's not too heavy
    def sitemap
      respond_to do |format|
        format.xml do
          sm = SiteMap.new
          if params[:page].nil?
            render xml: sm.sitemap_index, layout: false
          else
            render xml: sm.sitemap_page(params[:page]), layout: false
          end
        end
      end
    end

    # an application 404 page to make it look nicer
    def app_404
      render status: :not_found
    end

    private

    # TODO: need to change query so it's not tenant-specific
    def find_identifiers(my_tenant)
      join_conditions = <<-SQL
          INNER JOIN stash_engine_resources
                  ON stash_engine_identifiers.id = stash_engine_resources.identifier_id
          INNER JOIN stash_engine_users
                  ON stash_engine_resources.user_id = stash_engine_users.id
      SQL

      Identifier.select(:id, :identifier, :identifier_type, :updated_at).distinct
        .joins(join_conditions)
        .where('stash_engine_users.tenant_id = ?', my_tenant.tenant_id)
    end

    def gen_xml_from_identifiers(ar_identifiers)
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.urlset(xmlns: 'http://www.sitemaps.org/schemas/sitemap/0.9') do
          ar_identifiers.each { |iden| add_url(xml, iden) }
        end
      end
      builder.to_xml
    end

    def add_url(xml, identifier)
      xml.url do
        xml.loc "https://#{Rails.application.default_url_options[:host]}#{APP_CONFIG.stash_mount}/dataset/#{identifier}"
        xml.lastmod identifier.updated_at.strftime('%Y-%m-%d')
      end
    end
  end
end
