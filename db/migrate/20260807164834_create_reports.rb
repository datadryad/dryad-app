class CreateReports < ActiveRecord::Migration[8.0]
  def change
    create_table :reports do |t|
      t.string :title
      t.string :bucket
      t.string :s3_key
      t.datetime :time
      t.string :status
      t.string :report_type

      t.timestamps
    end
  end
end
