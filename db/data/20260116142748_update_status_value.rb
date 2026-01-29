# frozen_string_literal: true

class UpdateStatusValue < ActiveRecord::Migration[8.0]
  def up
    StashEngine::CurationActivity.where(status: 'submitted').update_all(status: 'queued')
  end

  def down
    StashEngine::CurationActivity.where(status: 'queued').update_all(status: 'submitted')
  end
end
