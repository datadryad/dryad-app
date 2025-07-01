# frozen_string_literal: true

class AddDownloadFilename < ActiveRecord::Migration[8.0]
  def up
    StashEngine::GenericFile.find_each {|f| f.update_columns(download_filename: f.upload_file_name)}
  end

  def down
    # raise ActiveRecord::IrreversibleMigration
  end
end