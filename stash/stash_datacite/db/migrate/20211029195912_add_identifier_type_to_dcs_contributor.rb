class AddIdentifierTypeToDcsContributor < ActiveRecord::Migration[5.2]
  def up
    add_column :dcs_contributors, :identifier_type, "ENUM('isni', 'grid', 'crossref_funder_id', 'ror', 'other') DEFAULT NULL",
               after: :contributor_type

    # because up to now, anything filled in with a name_identifier_id is of identifier_type 'crossref_funder_id'
    execute <<-SQL
      UPDATE dcs_contributors
      SET identifier_type = 'crossref_funder_id'
      WHERE name_identifier_id LIKE '%dx.doi.org%';
    SQL
  end

  def down
    remove_column :dcs_contributors, :identifier_type
  end
end
