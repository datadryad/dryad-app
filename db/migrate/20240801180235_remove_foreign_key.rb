class RemoveForeignKey < ActiveRecord::Migration[7.0]
  def change
    remove_foreign_key :stash_engine_resource_publications, :stash_engine_resources, if_exists: true
  end
end
