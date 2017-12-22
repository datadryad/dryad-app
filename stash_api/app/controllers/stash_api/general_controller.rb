require_dependency 'stash_api/application_controller'

module StashApi
  class GeneralController < ApplicationController

    # get /datasets
    def index
      respond_to do |format|
        format.json { render json: output }
        format.html {}
      end
    end

    private

    def output
      {
        '_links': {
          'self': {
            href: root_path
          },
          'stash:datasets': {
            href: datasets_path
          },
          curies: [
            {
              name: 'stash',
              href: 'https://github.com/CDLUC3/stash/blob/development/stash_api/link-relations.md#{rel}',
              templated: 'true'
            }
          ]
        }
      }
    end

  end
end
