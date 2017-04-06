# This migration comes from stash_datacite (originally 20160915212547)
class RemoveUnusedColsFromDcsAffiliations < ActiveRecord::Migration
  def change
    remove_columns(:dcs_affiliations, :campus, :logo, :url, :url_text)
  end
end
