class ChangeConceptDoiToConceptRecId < ActiveRecord::Migration[4.2]
  def change
    rename_column :stash_engine_zenodo_copies, :concept_doi, :conceptrecid
  end
end
