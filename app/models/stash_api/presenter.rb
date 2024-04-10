# frozen_string_literal: true

module StashApi
  module Presenter

    def self.included(base)
      def base.api_url_helper
        Rails.application.routes.url_helpers
      end
    end

    def api_url_helper
      self.class.api_url_helper
    end

    def stash_curie
      { curies: [
        {
          name: 'stash',
          href: 'https://github.com/datadryad/dryad-app/blob/main/documentation/apis/link_relations.md#{rel}', # rubocop:disable Lint/InterpolationCheck
          templated: 'true'
        }
      ] }
    end

  end
end
