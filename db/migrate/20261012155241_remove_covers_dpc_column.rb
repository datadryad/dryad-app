class RemoveCoversDpcColumn < ActiveRecord::Migration[8.0]
  def change
    remove_column :payment_configurations, :covers_dpc, :boolean
  end
end
