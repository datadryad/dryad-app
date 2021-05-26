class CreateStashEngineFrictionlessReports < ActiveRecord::Migration[5.2]
  def change
    create_table :stash_engine_frictionless_reports do |t|
      t.text :report
      t.belongs_to :generic_file, foreign_key: { to_table: :stash_engine_generic_files }, type: :integer,
                   index: {name: "index_stash_engine_frictionless_reports_on_generic_file_id"}

      t.timestamps
    end
  end
end
