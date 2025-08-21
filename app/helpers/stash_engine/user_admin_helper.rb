module StashEngine
  module UserAdminHelper

    def system_roles
      [
        ['superuser', 'Superuser <span>Can access and edit all pages and administrative menus.</span>'],
        ['manager',
         'Data manager <span>Can view and edit submissions, manage all submission data (deletions, payments, etc.), and manage accounts.</span>'],
        ['curator', 'Curator <span>Can view, edit, and curate all submissions. Auto curation assignment.</span>'],
        ['admin', 'Admin <span>Can view all submissions and curation pages.</span>']
      ]
    end

    def tenant_roles
      [
        ['curator', 'Curator <span>Can view, edit, and curate datasets with the associated institution.</span>'],
        ['admin', 'Admin <span>Can view all institution submissions and curation pages, and create datasets.</span>'],
        ['', 'Remove this institution role']
      ]
    end

    def publisher_roles
      [
        ['curator', 'Curator <span>Can view, edit, and curate datasets with the associated publisher.'],
        ['admin', 'Admin <span>Can view all publisher submissions and curation pages, and create datasets.</span>'],
        ['', 'Remove this publisher role']
      ]
    end

    def journal_roles
      [
        ['curator', 'Curator <span>Can view, edit, and curate datasets with the associated journal.</span>'],
        ['admin', 'Admin <span>Can view all journal submissions and curation pages, and create datasets.</span>'],
        ['', 'Remove this journal role']
      ]
    end

    def funder_roles
      [
        ['admin', 'Admin <span>Can view all funder submissions and curation pages, and create datasets.</span>'],
        ['', 'Remove this funder role']
      ]
    end

    def tenant_list
      [['', '']] + StashEngine::Tenant.enabled.collect { |t| [t.short_name, t.id] }
    end

    def publisher_list
      [['', '']] + StashEngine::JournalOrganization.order(:name).collect { |j| [j.name, j.id] }
    end

    def funder_list
      [['', '']] + StashEngine::Funder.exemptions.collect { |f| [f.name, f.id] }
    end

    def role_list(user)
      return 'User' unless user.roles&.admin_roles.present?

      user.roles.admin_roles.map do |r|
        type = r.role_object_type&.delete_prefix('StashEngine::')&.sub('JournalOrganization', 'Publisher')&.sub('Tenant', 'Institution')
        "#{type} #{r.role&.sub('manager', 'data manager')}".strip.capitalize
      end.join(', ')
    end

    def role_details(user)
      return 'User' unless user.roles&.admin_roles.present?

      user.roles.admin_roles.map do |r|
        type = r.role_object_type&.delete_prefix('StashEngine::')&.sub('JournalOrganization', 'Publisher')&.sub('Tenant', 'Institution')
        role = "#{type} #{r.role&.sub('manager', 'data manager')}".strip.capitalize
        obj = 'Dryad system'
        if r.role_object.present?
          obj = if r.role_object.respond_to?(:name)
                  r.role_object.name
                elsif r.role_object.respond_to?(:title)
                  r.role_object.title
                else
                  r.role_object.short_name
                end
        end
        "#{role}, #{obj}"
      end.join('; ')
    end

  end
end
