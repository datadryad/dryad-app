class CreateStashEngineJournals < ActiveRecord::Migration[4.2]
  def up
    create_table :stash_engine_journals do |t|
      t.string :title, index: true
      t.string :issn, index: true
      t.string :website
      t.text :description
      t.column :payment_plan_type, "ENUM('PREPAID', 'DEFERRED', 'SUBSCRIPTION')"
      t.string :payment_contact
      t.string :manuscript_number_regex
      t.string :sponsor_name
      t.string :stripe_customer_id
      t.text :notify_contacts
      t.text :review_contacts
      t.boolean :allow_review_workflow
      t.boolean :allow_embargo
      t.boolean :allow_blackout
      t.timestamps
    end
  end

  def down
    drop_table :stash_engine_journals
  end
end
