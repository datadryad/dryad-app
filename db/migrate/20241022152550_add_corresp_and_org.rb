class AddCorrespAndOrg < ActiveRecord::Migration[7.0]
  def change
    add_column :stash_engine_authors, :corresp, :boolean, default: false
    add_column :stash_engine_authors, :author_org_name, :string, limit: 255,  after: :author_last_name
  end
end
