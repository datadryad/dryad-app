class AddConceptsDoiToZenodoCopies < ActiveRecord::Migration
  def change
    add_column :stash_engine_zenodo_copies, :concept_doi, :string
    add_index :stash_engine_zenodo_copies, :concept_doi
  end
end
