# frozen_string_literal: true

class AddJournalIntegrationDate < ActiveRecord::Migration[8.0]
  def up
    man_journals = StashEngine::Journal.joins(:manuscripts)
        .where("stash_engine_manuscripts.created_at > '#{1.year.ago.iso8601}'")
    man_journals.each do |journal|
      journal.update(integrated_at: journal.manuscripts.order(created_at: :desc).first.created_at)
    end
    StashEngine::Journal.api_journals.each do |journal|
      activity = StashEngine::CurationActivity.where(user: journal.users).where("note like '% API %'").order(created_at: :desc).first
      journal.update(integrated_at: activity.created_at) if activity.present?
    end
  end

  def down
    #raise ActiveRecord::IrreversibleMigration
  end
end
