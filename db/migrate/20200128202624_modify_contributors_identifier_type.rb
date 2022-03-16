class ModifyContributorsIdentifierType < ActiveRecord::Migration[4.2]

  def change
    change_table :dcs_contributors do |t|
      t.change :name_identifier_id, :string
    end
  end
end
