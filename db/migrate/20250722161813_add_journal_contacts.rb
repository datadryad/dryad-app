class AddJournalContacts < ActiveRecord::Migration[8.0]
  def change
    remove_column :stash_engine_journals, :payment_contact, :string
    add_column :stash_engine_journals, :api_contacts, :text, after: :review_contacts
  end
end
