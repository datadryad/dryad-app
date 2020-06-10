module StashEngine
  class DownloadToken < ActiveRecord::Base
    belongs_to :resource, class_name: 'StashEngine::Resource'

    def availability_delay_seconds
      return 0 if available.nil?
      return 60 if (available - Time.new) < 0 # it was already supposed to be available, so who knows how long, lets guess 60 seconds
      (available - Time.new).ceil
    end
  end
end
