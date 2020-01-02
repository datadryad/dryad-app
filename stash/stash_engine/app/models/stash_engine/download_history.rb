module StashEngine
  class DownloadHistory < ActiveRecord::Base
    belongs_to :resource, class_name: 'StashEngine::Resource'
    belongs_to :file_upload, class_name: 'StashEngine::FileUpload'
    enum state: %w[downloading finished].map { |i| [i.to_sym, i] }.to_h
  end
end
