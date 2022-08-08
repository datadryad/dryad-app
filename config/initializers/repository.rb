require 'stash/repo'

module StashEngine
  def self.repository
    @repository ||= begin
      url_helpers = Rails.application.routes.url_helpers

      Rails.logger.debug("Initializing new instance of repository Stash::Merritt::Repository")
      repository_instance = Stash::Merritt::Repository.new(url_helpers: url_helpers, threads: APP_CONFIG.merritt_max_submission_threads)
      unless repository_instance.respond_to?(:submit)
        raise ArgumentError, "Repository Stash::Merritt::Repository does not appear to be a #{Stash::Repo::Repository}"
      end

      repository_instance
    end
  end
end
