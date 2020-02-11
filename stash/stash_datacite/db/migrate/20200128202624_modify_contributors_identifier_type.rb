class ModifyContributorsIdentifierType < ActiveRecord::Migration

  def change
    change_table :dcs_contributors do |t|
      t.change :name_identifier_id, :string
    end
  end
end
