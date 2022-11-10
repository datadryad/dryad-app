module StashEngine
  class WidgetsController < ApplicationController

    # if you render or redirect in a before action it terminates further actions
    before_action :require_referrer_and_pub_id
    before_action :require_id_format
    before_action :require_id_exists
    before_action :require_publicly_viewable

    def banner_for_pub
      send_file File.join(Rails.root, 'public', 'data_in_dryad.jpg'), type: 'image/jpeg', disposition: 'inline'
    end

    def data_package_for_pub
      redirect_to stash_url_helpers.show_path(id: @stash_id.to_s)
    end

    private

    # they need to include these params for this request to be valid
    def require_referrer_and_pub_id
      not_found if params[:referrer].blank? || params['pubId'].blank?
    end

    def require_id_format
      # getting the actual id in the kept capture group
      # matches all these types of variations
      # https://doi.org/10.5061/dryad.b6vh6
      # https://dx.doi.org/10.5061/dryad.b6vh6
      # http://doi.org/10.5061/dryad.b6vh6
      # http://dx.doi.org/10.5061/dryad.b6vh6
      # doi:10.5061/dryad.b6vh6
      @doi = params['pubId'].scan(%r{^(?:(?:https?://(?:dx\.)?doi.org/)|(?:doi:))(.+)$}).flatten.first
      @pmid = params['pubId'].scan(/^pmid:(\d+)$/).flatten.first
      not_found if @doi.blank? && @pmid.blank?
    end

    def require_id_exists
      pmid = InternalDatum.find_by(data_type: 'pubmedID', value: @pmid)
      doi = StashDatacite::RelatedIdentifier.find_by(related_identifier_type: 'doi', relation_type: 'isCitedBy',
                                                     related_identifier: @doi)
      @stash_id = pmid.stash_identifier unless pmid.blank?
      @stash_id = doi.resource.identifier if @stash_id.blank? && doi.present?
      not_found if @stash_id.blank?
    end

    def require_publicly_viewable
      not_found if @stash_id.latest_resource_with_public_metadata.blank?
    end

    def not_found
      if params[:action] == 'data_package_for_pub'
        # make this page show not-available instead of redirecting elsewhere
        render('stash_engine/landing/not_available', status: 404)
        # redirect_to show_path(id: @stash_id&.to_s || 'not_available')
      else
        # show the 1x1 transparent gif
        send_file File.join(Rails.root, 'public', 'transparent.gif'), type: 'image/gif', disposition: 'inline', status: 404
      end
    end
  end
end
