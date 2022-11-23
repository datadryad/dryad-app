module StashEngine
  class OrcidInvitation < ApplicationRecord
    self.table_name = 'stash_engine_orcid_invitations'
    belongs_to :identifier, class_name: 'StashEngine::Identifier'

    def resource
      @resource ||= identifier.last_submitted_resource || identifier.latest_resource
    end

    def tenant
      @tenant ||= resource.tenant
    end

    def landing(path)
      u = URI.parse(path)
      "#{tenant.full_url(u.path)}#{u.query ? "?#{u.query}" : ''}"
    end
  end
end
