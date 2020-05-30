module StashEngine
  class DownloadToken < ActiveRecord::Base
    belongs_to :resource, class_name: 'StashEngine::Resource'

    def availability_delay_seconds
      return 0 if available.nil? || (Time.new - available) < 0
      (Time.new - available).ceil
    end
  end
end
