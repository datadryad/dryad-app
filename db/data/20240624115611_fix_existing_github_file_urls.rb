# frozen_string_literal: true

class FixExistingGithubFileUrls < ActiveRecord::Migration[7.0]
  def up
    files = StashEngine::GenericFile.where("url like '%https://github.com%'")
    puts "Updating #{files.count} files"

    files.each do |file|
      print '.'
      translator = Stash::UrlTranslator.new(file.url)
      file.update_columns(original_url: file.url, url: translator.direct_download || file.url)
    end

    puts ''
    puts 'Finished'
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
