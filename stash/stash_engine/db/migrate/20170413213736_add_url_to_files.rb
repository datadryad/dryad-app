class AddUrlToFiles < ActiveRecord::Migration
  def change
    change_table :stash_engine_file_uploads do |fu|
      fu.column :url, :text
      fu.index :url, length: 50
      fu.column :status_code, :integer, index: true
      fu.column :timed_out, :boolean, index: true, default: false
    end
  end
end
