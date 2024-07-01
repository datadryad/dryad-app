class AddRolesTable < ActiveRecord::Migration[6.1]
  JOURNAL_ROLE = <<-SQL.freeze
    INSERT INTO stash_engine_roles (user_id, role, role_object_type, role_object_id) SELECT user_id, role, 'StashEngine::Journal', journal_id FROM stash_engine_journal_roles WHERE `stash_engine_journal_roles`.`role` = 'admin'
  SQL
  JOURNAL_ORG_ROLE = <<-SQL.freeze
    INSERT INTO stash_engine_roles (user_id, role, role_object_type, role_object_id) SELECT user_id, 'admin', 'StashEngine::JournalOrganization', journal_organization_id FROM stash_engine_journal_roles WHERE `stash_engine_journal_roles`.`role` = 'org_admin'
  SQL
  FUNDER_ROLE = <<-SQL.freeze
    INSERT INTO stash_engine_roles (user_id, role, role_object_type, role_object_id) SELECT user_id, 'admin', 'StashEngine::Funder', 1 FROM stash_engine_funder_roles
  SQL
  ROLE_JOURNAL = <<-SQL.freeze
    INSERT INTO stash_engine_journal_roles (user_id, role, journal_id) SELECT user_id, 'admin', role_object_id FROM stash_engine_roles where role_object_type = 'StashEngine::Journal'
  SQL
  ROLE_JOURNAL_ORG = <<-SQL.freeze
    INSERT INTO stash_engine_journal_roles (user_id, role, journal_organization_id) SELECT user_id, 'org_admin', role_object_id FROM stash_engine_roles where role_object_type = 'StashEngine::JournalOrganization'
  SQL
  ROLE_FUNDER = <<-SQL.freeze
    INSERT INTO stash_engine_funder_roles (user_id, role, funder_name, funder_id) SELECT user_id, 'admin', 'Chan Zuckerberg Initiative', 'https://ror.org/02qenvm24' FROM stash_engine_roles where role_object_type = 'StashEngine::Funder'
  SQL
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
        execute JOURNAL_ROLE
        execute JOURNAL_ORG_ROLE
        execute FUNDER_ROLE
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
        execute ROLE_JOURNAL
        execute ROLE_JOURNAL_ORG
        execute ROLE_FUNDER
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
