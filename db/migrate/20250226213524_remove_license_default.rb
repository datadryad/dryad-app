class RemoveLicenseDefault < ActiveRecord::Migration[8.0]
  def change
    def change
      change_column_default :stash_engine_identifiers, :license_id, from: 'cc0', to: nil
    end
  end
end
