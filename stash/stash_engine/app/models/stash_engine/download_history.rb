module StashEngine
  class DownloadHistory < ActiveRecord::Base
    belongs_to :resource, class_name: 'StashEngine::Resource'
    belongs_to :file_upload, class_name: 'StashEngine::FileUpload'
    enum state: %w[downloading finished].map { |i| [i.to_sym, i] }.to_h

    scope :downloading, -> { where(state: 'downloading') }

    def self.mark_start(ip:, user_agent:, resource_id:, file_id: nil)
      create(ip_address: ip, user_agent: user_agent, resource_id: resource_id, file_upload_id: file_id, state: 'downloading')
    end

    # this just changes the status so it is marked as finished
    def self.mark_end(download_history: nil)
      return if download_history.nil?

      download_history.update(state: 'finished')
    end

  end
end
