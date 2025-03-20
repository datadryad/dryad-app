class AddLastInvoicedFileSizeToIdentifiers < ActiveRecord::Migration[8.0]
  def change
    add_column :stash_engine_identifiers, :last_invoiced_file_size, :bigint
  end
end
