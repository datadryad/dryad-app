class ChangeCurationActivityNoteToText < ActiveRecord::Migration
  def change
    change_column :stash_engine_curation_activities, :note, :text
  end
end
