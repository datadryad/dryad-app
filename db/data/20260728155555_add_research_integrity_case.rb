# frozen_string_literal: true

class AddResearchIntegrityCase < ActiveRecord::Migration[8.0]
  def up
    notes = StashEngine::CurationActivity.where("note like 'Crossref found retraction of primary article%'").uniq {|ca| ca.identifier_id}
    notes.each {|ca| ResearchIntegrityCase.create(identifier_id: ca.identifier_id, curation_activity_id: ca.id)}
  end

  def down
    # raise ActiveRecord::IrreversibleMigration
  end
end
