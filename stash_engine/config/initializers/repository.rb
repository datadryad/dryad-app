require 'stash/repo'

module StashEngine
  def self.repository
    @repository ||= begin
      repository_class_name = APP_CONFIG.repository
      Rails.logger.debug("StashEngine.app.repository = #{repository_class_name}")

      repository_class = repository_class_name.constantize
      url_helpers = StashEngine::Engine.routes.url_helpers

      Rails.logger.debug("Initializing new instance of repository #{repository_class}")
      repository_instance = repository_class.new(url_helpers: url_helpers, threads: APP_CONFIG.merritt_max_submission_threads)
      raise ArgumentError, "Repository #{repository_instance.class} does not appear to be a #{Stash::Repo::Repository}" unless repository_instance.respond_to?(:submit)

      repository_instance
    end
  end
end
