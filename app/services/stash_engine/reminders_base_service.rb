module StashEngine
  class RemindersBaseService
    attr_reader :logging

    def initialize(logging: false)
      @logging = logging
    end

    private

    def create_activity(flag, resource, status: nil, note: nil)
      status ||= resource.last_curation_activity.status
      StashEngine::CurationActivity.create(
        resource_id: resource.id,
        user_id: 0,
        status: status,
        note: note || "#{flag} - reminded submitter that this item is still `#{status}`"
      )
    end

    def log(message)
      return unless logging
      return if Rails.env.test?

      puts message
    end

    def log_data_for_status(status, resource)
      text = "Mailing submitter about deletion of #{status} dataset. "
      text += resource_log_text(resource)
      log(text)
    end

    def resource_log_text(resource)
      " Identifier: #{resource.identifier_id}, Resource: #{resource.id} updated #{resource.updated_at}"
    end
  end
end
