class AddFileValidDate < ActiveRecord::Migration[6.1]
  def change
    add_column :stash_engine_generic_files, :validated_at, :datetime, after: :updated_at
  end
end
