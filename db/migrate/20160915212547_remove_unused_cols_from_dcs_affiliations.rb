class RemoveUnusedColsFromDcsAffiliations < ActiveRecord::Migration[4.2]
  def change
    remove_columns(:dcs_affiliations, :campus, :logo, :url, :url_text)
  end
end
