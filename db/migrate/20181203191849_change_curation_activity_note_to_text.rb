class ChangeCurationActivityNoteToText < ActiveRecord::Migration[4.2]
  def change
    change_column :stash_engine_curation_activities, :note, :text
  end
end
