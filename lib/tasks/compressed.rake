namespace :compressed do
  task update_contents: :environment do
    $stdout.sync = true # keeps stdout from buffering which causes weird delays such as with tail -f

    puts "#{Time.new.iso8601} Starting update of container_contents for compressed files"

    db_files =
      StashEngine::DataFile.joins(resource: :current_resource_state).left_joins(:container_files)
        .where("stash_engine_resource_states.resource_state = 'submitted'")
        .where(container_files: { id: nil })
        .where(file_state: %w[copied created])
        .where("upload_file_name LIKE '%.zip' OR upload_file_name LIKE '%.tar.gz' OR upload_file_name LIKE '%.tgz'")
        .order(resource_id: :asc).distinct

    count = db_files.count

    db_files.each_with_index do |db_file, idx|

      if db_file.copied?
        puts "#{idx + 1}/#{count} Copying container_contents for #{db_file.upload_file_name} (id: #{db_file.id}, " \
             "resource_id: #{db_file.resource_id}) from previous unchanged file"

        db_file.populate_container_files_from_last
        next
      end

      sleep 1 # so we don't bomb merritt with presigned URL requests
      puts "#{idx + 1}/#{count} Updating container_contents for #{db_file.upload_file_name} (id: #{db_file.id}, " \
           "resource_id: #{db_file.resource_id})"

      to_insert = Tasks::Compressed::Info.files(db_file: db_file).map do |file_info|
        { data_file_id: db_file.id, path: file_info[:path], mime_type: file_info[:mime_type], size: file_info[:size] }
      end.first(1000) # only do 1000 if there are more than that, they are probably repetitive

      StashEngine::ContainerFile.insert_all(to_insert)

    rescue StandardError => e
      puts "#{idx + 1}/#{count} Error updating container_contents for #{db_file.upload_file_name} (id: #{db_file.id}, " \
           "resource_id: #{db_file.resource_id}): #{e.message}"
      puts "  Error: #{e.class} #{e.message}\n  #{e.backtrace.join("\n  ")}"
      db_file.container_files.delete_all
    end

    puts "#{Time.new.iso8601} Finished update of container_contents for compressed files"
  end

  # a simplified version of the above task that only updates one resource for testing and doesn't catch errors
  task update_one: :environment do
    $stdout.sync = true # keeps stdout from buffering which causes weird delays such as with tail -f

    if ARGV.length != 1
      puts 'Please enter the file id as the only argument to this task'
      exit
    end

    db_file = StashEngine::DataFile.find(ARGV[0])

    puts "Updating container_contents for #{db_file.upload_file_name} (id: #{db_file.id}, " \
         "resource_id: #{db_file.resource_id})"

    db_file.container_files.delete_all

    to_insert = Tasks::Compressed::Info.files(db_file: db_file).map do |file_info|
      { data_file_id: db_file.id, path: file_info[:path], mime_type: file_info[:mime_type], size: file_info[:size] }
    end.first(1000)

    StashEngine::ContainerFile.insert_all(to_insert)

    exit
  end
end
