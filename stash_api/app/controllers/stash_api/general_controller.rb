# frozen_string_literal: true

require_dependency 'stash_api/application_controller'

module StashApi
  class GeneralController < ApplicationController

    before_action :require_json_headers
    before_action :doorkeeper_authorize!, only: :test
    before_action :require_api_user, only: :test

    # get /datasets
    def index
      respond_to do |format|
        format.json { render json: output }
      end
    end

    # post /test
    # see if you can do a post request and connect with the key you've obtained
    def test
      respond_to do |format|
        format.json { render json: { message: "Welcome application owner #{@user.name}", user_id: @user.id } }
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
          href: 'https://github.com/CDL-Dryad/stash/blob/master/stash_api/link-relations.md#{rel}', # rubocop:disable Lint/InterpolationCheck
          templated: 'true'
        }
      ]
    end

  end
end
