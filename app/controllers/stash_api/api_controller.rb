# frozen_string_literal: true

module StashApi
  class ApiController < ApiApplicationController

    before_action :require_json_headers
    before_action :force_json_content_type
    before_action :doorkeeper_authorize!, only: :test
    before_action :require_api_user, only: :test

    # get /
    # All this really does is return the basic HATEOAS link to the base level dataset links
    def index
      render json: output
    end

    # post /test
    # see if you can do a post request and connect with the key you've obtained
    def test
      render json: { message: "Welcome application owner #{@user.name}", user_id: @user.id }
    end

    def reports
      render json: { message: "Requested report #{params['report_name']}" }
    end

    private

    def output
      {
        _links: {
          self: root_self,
          'stash:datasets': {
            href: datasets_path
          },
          curies: curies
        }
      }
    end

    def root_self
      {
        href: '/api/v2/'
      }
    end

    def curies
      [
        {
          name: 'stash',
          href: 'https://github.com/CDL-Dryad/stash/blob/main/stash_api/link-relations.md#{rel}', # rubocop:disable Lint/InterpolationCheck
          templated: 'true'
        }
      ]
    end

  end
end
