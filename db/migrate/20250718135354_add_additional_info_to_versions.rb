class AddAdditionalInfoToVersions < ActiveRecord::Migration[8.0]
  def change
    add_column :paper_trail_versions, :additional_info, :json
  end
end
