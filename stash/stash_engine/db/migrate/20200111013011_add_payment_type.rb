class AddPaymentType < ActiveRecord::Migration
  def up
    rename_column :stash_engine_identifiers, :invoice_id, :payment_id
    add_column :stash_engine_identifiers, :payment_type, :string, after: :search_words
    StashEngine::Identifier.reset_column_information
    StashEngine::Identifier.all.each do |i|
      if i.payment_id
        if i.payment_id.start_with?('in_')
          i.update_column(:payment_type, 'stripe')
        else          
          # else, separate on the colon, set payment_type to part before colon, and payment_id to rest
          found_type, found_id = i.payment_id.match(/(.+):(.+)/).captures
          next unless found_type && found_id
          i.update_column(:payment_id, found_id)
          i.update_column(:payment_type, found_type)
        end
      end
    end
  end

  def down
    StashEngine::Identifier.all.each do |i|
      if i.payment_id
        if i.payment_type != 'stripe'
          new_id = "#{i.payment_type}:#{i.payment_id}"
          i.update_column(:payment_id, new_id)
        end
      end
    end
    rename_column :stash_engine_identifiers, :payment_id, :invoice_id
    remove_column :stash_engine_identifiers, :payment_type
  end
end
