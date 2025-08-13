# frozen_string_literal: true

class AddContribGroupRequired < ActiveRecord::Migration[8.0]
  def up
    group = StashDatacite::ContributorGrouping.where(name_identifier_id: 'https://ror.org/01cwqze88').first
    group&.update(group_label: 'NIH Institute or Center', required: true)
  end

  def down
    #raise ActiveRecord::IrreversibleMigration
  end
end
