class AddRolesTable < ActiveRecord::Migration[6.1]
  def change
    create_table :stash_engine_funders do |t|
      t.string :name
      t.string :ror_id
      t.integer :payment_plan
      t.boolean :enabled, default: true
      t.boolean :covers_dpc, default: true
      t.timestamps
    end
    add_index :stash_engine_funders, :ror_id
    StashEngine::Funder.create(name: 'Chan Zuckerberg Initiative', ror_id: 'https://ror.org/02qenvm24')
    create_table :stash_engine_roles do |t|
      t.integer :user_id
      t.string :role      
      t.string :role_object_type
      t.string :role_object_id
      t.timestamps
    end
    add_index :stash_engine_roles, :user_id
    add_index :stash_engine_roles, [:role_object_type, :role_object_id]
    add_foreign_key :stash_engine_roles, :stash_engine_users, column: :user_id
    reversible do |dir|
      dir.up do
        StashEngine::JournalRole.all.each do |r|
          StashEngine::Role.create(user_id: r.user_id, role: 'admin', role_object: StashEngine::Journal.find(r.journal_id)) if r.journal_id.present? && StashEngine::Journal.exists?(r.journal_id)
          StashEngine::Role.create(user_id: r.user_id, role: 'admin', role_object: StashEngine::JournalOrganization.find(r.journal_organization_id)) if r.journal_organization_id.present? && StashEngine::JournalOrganization.exists?(r.journal_organization_id)
        end
        StashEngine::FunderRole.all.each do |r|
          StashEngine::Role.create(user_id: r.user_id, role: r.role, role_object: StashEngine::Funder.find_by(name: r.funder_name)) if StashEngine::Funder.find_by(name: r.funder_name).exists?
        end
        StashEngine::User.where("role != 'user'").each do |u|
          case u.role
            when 'limited_curator'
              StashEngine::Role.create(user_id: u.id, role: 'admin')
            when 'curator'
              StashEngine::Role.create(user_id: u.id, role: 'curator')
            when 'superuser'
              StashEngine::Role.create(user_id: u.id, role: 'superuser')
            when 'admin'
              StashEngine::Role.create(user_id: u.id, role: 'admin', role_object: StashEngine::Tenant.find(u.tenant_id)) if StashEngine::Tenant.exists?(u.tenant_id)
            when 'tenant_curator'
              StashEngine::Role.create(user_id: u.id, role: 'curator', role_object: StashEngine::Tenant.find(u.tenant_id)) if StashEngine::Tenant.exists?(u.tenant_id)
          end
        end
      end
      dir.down do
        StashEngine::Role.journal_roles.each do |r|
          StashEngine::JournalRole.create(user_id: r.user_id, role: 'admin', journal_id: r.role_object_id)
        end
        StashEngine::Role.journal_org_roles.each do |r|
          StashEngine::JournalRole.create(user_id: r.user_id, role: 'org_admin', journal_organization_id: r.role_object_id)
        end
        StashEngine::Role.funder_roles.each do |r|
          funder = StashEngine::Funder.find(r.role_object_id)
          StashEngine::FunderRole.create(user_id: r.user_id, role: 'admin', funder_name: funder.name, funder_id: funder.ror_id)
        end
        StashEngine::Role.system_roles.admin.each {|r| StashEngine::User.find(r.user_id).update(role: 'limited_curator') if StashEngine::User.exists?(r.user_id)}
        StashEngine::Role.system_roles.curator.each {|r| StashEngine::User.find(r.user_id).update(role: 'curator') if StashEngine::User.exists?(r.user_id)}
        StashEngine::Role.superuser.each {|r| StashEngine::User.find(r.user_id).update(role: 'superuser') if StashEngine::User.exists?(r.user_id)}
        StashEngine::Role.tenant_roles.admin.each {|r| StashEngine::User.find(r.user_id).update(role: 'admin') if StashEngine::User.exists?(r.user_id)}
        StashEngine::Role.tenant_roles.curator.each {|r| StashEngine::User.find(r.user_id).update(role: 'tenant_curator') if StashEngine::User.exists?(r.user_id)}
      end
    end
    drop_table :stash_engine_funder_roles do |t|
      t.string :funder_name
      t.string :role
      t.string :funder_id
      t.bigint :user_id
      t.timestamps
    end
    drop_table :stash_engine_journal_roles do |t|
      t.integer :user_id
      t.integer :journal_id
      t.string :role
      t.integer :journal_organization_id
      t.timestamps
    end
  end
end
