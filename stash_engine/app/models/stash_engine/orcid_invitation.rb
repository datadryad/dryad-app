module StashEngine
  class OrcidInvitation < ActiveRecord::Base
    belongs_to :identifier, class_name: 'StashEngine::Identifier'

    def resource
      @resource ||= identifier.last_submitted_resource
    end

    def tenant
      @tenant ||= resource.tenant
    end

    def landing(path)
      tenant.full_url(path)
    end
  end
end
