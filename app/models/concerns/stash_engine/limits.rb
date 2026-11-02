require 'active_support/concern'

module StashEngine
  module Limits
    extend ActiveSupport::Concern

    def new_upload_size_limit
      payer_2025? || sponsored?
    end

    def size_limit
      new_upload_size_limit ? APP_CONFIG.maximums.upload_size : APP_CONFIG.maximums.merritt_size
    end
  end
end
