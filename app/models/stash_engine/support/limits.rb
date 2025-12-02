require 'active_support/concern'

module StashEngine
  module Support
    module Limits
      extend ActiveSupport::Concern

      def new_upload_size_limit
        payer_2025? || sponsored?
      end
    end
  end
end
