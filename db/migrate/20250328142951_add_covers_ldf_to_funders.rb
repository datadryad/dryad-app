class AddCoversLdfToFunders < ActiveRecord::Migration[8.0]
  def change
    add_column :stash_engine_funders, :covers_ldf, :string, after: :covers_dpc
  end
end
