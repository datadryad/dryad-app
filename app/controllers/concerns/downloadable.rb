require 'stash/download/version_presigned'

module Concerns
  module Downloadable
    extend ActiveSupport::Concern
    include ActionView::Helpers::DateHelper

    private

    # this really requires resource passed in and @user to be set (if there is one)
    def download_version(resource:)
      @version_presigned = Stash::Download::VersionPresigned.new(resource: resource)
      if resource&.may_download?(ui_user: @user) && @version_presigned.valid_resource?
        @status_hash = @version_presigned.download
        case @status_hash[:status]
        when 200
          StashEngine::CounterLogger.version_download_hit(request: request, resource: resource)
          redirect_to @status_hash[:url]
        when 202
          render status: 202,
                 plain: 'The version of the dataset is being assembled. ' \
                        "Check back in around #{time_ago_in_words(resource.download_token.available + 30.seconds)} " \
                        'and it should be ready to download.'
        when 408
          render status: 503, plain: 'Download Service Unavailable for this request'
        else
          render status: 404, plain: 'Not found'
        end
      else
        render plain: 'download for this version of the dataset is unavailable', status: 404
      end
    end
  end
end
