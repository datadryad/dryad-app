class DeleteRelatedSchemeInfoFromRelationTypes < ActiveRecord::Migration
  def change
    change_table :dcs_relation_types do |t|
      t.remove :related_metadata_scheme
      t.remove :scheme_URI
      t.remove :scheme_type
    end
  end
end
