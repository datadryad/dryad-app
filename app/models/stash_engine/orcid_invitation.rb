# == Schema Information
#
# Table name: stash_engine_orcid_invitations
#
#  id            :integer          not null, primary key
#  email         :string(191)
#  identifier_id :integer
#  first_name    :string(191)
#  last_name     :string(191)
#  secret        :string(191)
#  orcid         :string(191)
#  invited_at    :datetime         not null
#  accepted_at   :datetime
#
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
