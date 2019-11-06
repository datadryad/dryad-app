class CreateDcsSubjects < ActiveRecord::Migration
  def change
    create_table :dcs_subjects do |t|
      t.string :subject
      t.string :subject_scheme
      t.text   :scheme_URI
      t.integer :resource_id

      t.timestamps null: false
    end
  end
end
