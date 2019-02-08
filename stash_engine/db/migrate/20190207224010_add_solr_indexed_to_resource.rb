class AddSolrIndexedToResource < ActiveRecord::Migration
  def change
    add_column :stash_engine_resources, :solr_indexed, :boolean, default: false
  end
end
