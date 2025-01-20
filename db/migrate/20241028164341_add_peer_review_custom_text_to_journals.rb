class AddPeerReviewCustomTextToJournals < ActiveRecord::Migration[7.0]
  def change
    add_column :stash_engine_journals, :peer_review_custom_text, :text
  end
end
