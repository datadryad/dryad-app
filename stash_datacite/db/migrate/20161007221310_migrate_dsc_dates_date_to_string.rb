class MigrateDscDatesDateToString < ActiveRecord::Migration
  def self.up
    add_column(:dcs_dates, :new_date, :string, after: :date)

    StashDatacite::DataciteDate.all.each do |date_obj|
      date_obj.update_column(:new_date, date_obj.date.iso8601) unless date_obj.date.nil?
    end

    remove_column :dcs_dates, :date

    rename_column :dcs_dates, :new_date, :date

    StashDatacite::DataciteDate.reset_column_information
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
