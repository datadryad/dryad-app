class ChangeConceptDoiToConceptRecId < ActiveRecord::Migration
  def change
    rename_column :stash_engine_zenodo_copies, :concept_doi, :conceptrecid
  end
end
