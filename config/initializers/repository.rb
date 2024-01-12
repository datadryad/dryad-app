require 'stash/repo'

module StashEngine
  def self.repository
    @repository ||= begin
      url_helpers = Rails.application.routes.url_helpers

      Rails.logger.debug("Initializing new instance of repository Stash::Repo::Repository")
      Stash::Repo::Repository.new(url_helpers: url_helpers, threads: APP_CONFIG.merritt_max_submission_threads)
    end
  end
end
