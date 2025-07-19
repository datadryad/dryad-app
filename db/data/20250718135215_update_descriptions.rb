# frozen_string_literal: true

class UpdateDescriptions < ActiveRecord::Migration[8.0]
  def up
    StashDatacite::Description.where(description_type: 'usage_notes').update_all(description_type: 'hsi_statement')
  end

  def down
    StashDatacite::Description.where(description_type: 'hsi_statement').update_all(description_type: 'usage_notes')
  end
end
