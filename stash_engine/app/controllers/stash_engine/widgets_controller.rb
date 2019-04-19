require_dependency 'stash_engine/application_controller'

module StashEngine
  class WidgetsController < ApplicationController

    before_action :require_referrer_and_pub_id

    def banner_for_pub
      render text: 'Hi there'
    end

    def data_package_for_pub
      render text: 'Bye there'
    end

    private

    # they need to include these params for this request to be valid
    def require_referrer_and_pub_id
      render text: 'Not found', status: :not_found if params[:referrer].blank? && params['pubId'].blank?
    end

    def require_id_format
      # matches all these variations
      # https://doi.org/10.5061/dryad.b6vh6
      # https://dx.doi.org/10.5061/dryad.b6vh6
      # http://doi.org/10.5061/dryad.b6vh6
      # http://dx.doi.org/10.5061/dryad.b6vh6
      # doi:10.5061/dryad.b6vh6
      %r{^(?:(?:https?://(?:dx\.)?doi.org/)|(?:doi:))(.+)$}

      # pmid:18183754
      /^pmid:(\d+)$/
    end
  end
end