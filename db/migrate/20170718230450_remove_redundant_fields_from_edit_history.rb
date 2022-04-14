class RemoveRedundantFieldsFromEditHistory < ActiveRecord::Migration[4.2]
  def change
    change_table :stash_engine_edit_histories do |t|
      t.remove :identifier_id
      t.remove :user_id
    end
  end
end
