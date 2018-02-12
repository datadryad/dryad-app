# frozen_string_literal: true

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
          'self': root_self,
          'stash:datasets': {
            href: datasets_path
          },
          curies: curies
        }
      }
    end

    def root_self
      {
        href: root_path
      }
    end

    def curies
      [
        {
          name: 'stash',
          href: 'https://github.com/CDLUC3/stash/blob/development/stash_api/link-relations.md#{rel}',
          templated: 'true'
        }
      ]
    end

  end
end
