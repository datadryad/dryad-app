class AddSkipEmailAndLoosenValidationToResource < ActiveRecord::Migration
  def change
    add_column :stash_engine_resources, :skip_emails, :boolean, default: false
    add_column :stash_engine_resources, :loosen_validation, :boolean, default: false
  end
end
