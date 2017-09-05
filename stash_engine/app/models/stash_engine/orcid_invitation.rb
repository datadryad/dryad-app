module StashEngine
  class OrcidInvitation < ActiveRecord::Base
    belongs_to :identifier, class_name: 'StashEngine::Identifier'

    def resource
      @res ||= identifier.last_submitted_resource
    end

    def tenant
      @tenant ||= resource.tenant
    end

    def landing(path)
      # current_tenant.full_url(stash_url_helpers.show_path(identifier))
      tenant.full_url(path)
    end

    def register_orcid(path)
      hsh = { 'invitation' => secret }
      "#{landing(path)}?#{hsh.to_query}"
    end
  end
end
