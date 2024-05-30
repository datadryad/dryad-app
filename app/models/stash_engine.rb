module StashEngine
  def self.repository
    @repository ||= begin
      Rails.logger.debug('Initializing new instance of repository Stash::Repo::Repository')
      Stash::Repo::Repository.new(threads: APP_CONFIG.merritt_max_submission_threads)
    end
  end
end
