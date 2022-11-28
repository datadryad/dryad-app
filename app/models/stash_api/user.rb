# frozen_string_literal: true

module StashApi
  class User
    include Presenter

    def initialize(user_id:)
      @se_user = StashEngine::User.find(user_id)
    end

    def metadata
      afilliation = StashDatacite::Affiliation.find(@se_user.affiliation_id) if @se_user.affiliation_id
      { _links: links }.merge(
        id: @se_user.id,
        firstName: @se_user.first_name,
        lastName: @se_user.last_name,
        email: @se_user.email,
        tenantId: @se_user.tenant_id,
        role: @se_user.role,
        orcid: @se_user.orcid,
        affiliation: afilliation&.long_name,
        affiliationROR: afilliation&.ror_id,
        oldDryadEmail: @se_user.old_dryad_email,
        ePersonId: @se_user.eperson_id,
        createdAt: @se_user.created_at
      )
    end

    def links
      basic_links.compact.merge(stash_curie)
    end

    def parent_version
      @version ||= Version.new(resource_id: @se_data_file.resource_id)
    end

    private

    def basic_links
      { self: { href: api_url_helper.user_path(@se_user.id) } }
    end

  end
end
