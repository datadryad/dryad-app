class AddSolrIndexedToResource < ActiveRecord::Migration[4.2]
  def change
    add_column :stash_engine_resources, :solr_indexed, :boolean, default: false
  end
end
