namespace :file do

  desc 'many file_upload.temp_file_paths contain a releases directory, change to current instead until we can fix this'
  task path_hack:  :environment do
    StashEngine::FileUpload.where("temp_file_path LIKE '%/releases/%'").each do |fu|
      changed = fu.temp_file_path.gsub(%r{/releases/\d+/}, '/current/')
      fu.update_column(:temp_file_path, changed)
      puts "updated: #{changed}"
    end
  end
end