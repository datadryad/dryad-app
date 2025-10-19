class AddVersionIndex < ActiveRecord::Migration[8.0]
  def change
    add_index :paper_trail_versions, :created_at
  end
end
