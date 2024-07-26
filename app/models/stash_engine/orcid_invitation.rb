# == Schema Information
#
# Table name: stash_engine_orcid_invitations
#
#  id            :integer          not null, primary key
#  accepted_at   :datetime
#  email         :string(191)
#  first_name    :string(191)
#  invited_at    :datetime         not null
#  last_name     :string(191)
#  orcid         :string(191)
#  secret        :string(191)
#  identifier_id :integer
#
# Indexes
#
#  index_stash_engine_orcid_invitations_on_email          (email)
#  index_stash_engine_orcid_invitations_on_identifier_id  (identifier_id)
#  index_stash_engine_orcid_invitations_on_orcid          (orcid)
#  index_stash_engine_orcid_invitations_on_secret         (secret)
#
module StashEngine
  class OrcidInvitation < ApplicationRecord
    self.table_name = 'stash_engine_orcid_invitations'
    belongs_to :identifier, class_name: 'StashEngine::Identifier'

    def resource
      @resource ||= identifier.last_submitted_resource || identifier.latest_resource
    end

    def tenant
      @tenant ||= resource.tenant || StashEngine::Tenant.find(APP_CONFIG.default_tenant)
    end

    def landing(path)
      u = URI.parse(path)
      "#{tenant.full_url(u.path)}#{u.query ? "?#{u.query}" : ''}"
    end
  end
end
