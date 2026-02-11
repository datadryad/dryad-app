# :nocov:

namespace :compressed do
  # Enqueues up to 1000 archive files to analyze for container_contents
  # example: rails/rake compressed:update_contents
  task update_contents: :environment do
    parsing_limit = 1000
    puts ''
    puts "#{Time.new.iso8601} Starting enqueuing of container_contents for compressed files"

    db_files =
      StashEngine::DataFile.joins(resource: :current_resource_state).left_joins(:container_files)
        .where("stash_engine_resource_states.resource_state = 'submitted'")
        .where(container_files: { id: nil })
        .where(file_state: %w[copied created])
        .where("upload_file_name LIKE '%.zip' OR upload_file_name LIKE '%.tar.gz' OR upload_file_name LIKE '%.tgz'")
        .where('compressed_try < 3')
        .order(resource_id: :asc)
        .distinct

    count = db_files.count
    puts "Enqueueing #{parsing_limit} of #{count} archives for analyzing"

    db_files.limit(parsing_limit).each do |db_file|
      ArchiveAnalyzerJob.perform_async(db_file.id)
    end

    puts "#{Time.new.iso8601} Finished enqueuing of container_contents for compressed files"
  end

  # a simplified version of the above task that only updates one resource for testing and doesn't catch errors
  # example: rails/rake compressed:update_one -- --file_id 10
  task update_one: :environment do
    $stdout.sync = true # keeps stdout from buffering which causes weird delays such as with tail -f
    args = Tasks::ArgsParser.parse(:file_id)

    unless args.file_id
      puts 'Please enter the file id as the only argument to this task'
      exit
    end

    db_file = StashEngine::DataFile.find(args.file_id)

    puts "Updating container_contents for #{db_file.upload_file_name} (id: #{db_file.id}, " \
         "resource_id: #{db_file.resource_id})"

    db_file.container_files.delete_all

    to_insert = Tasks::Compressed::Info.files(db_file: db_file).map do |file_info|
      { data_file_id: db_file.id, path: file_info[:path], mime_type: file_info[:mime_type], size: file_info[:size] }
    end.first(1000)

    if to_insert.empty?
      puts "  No files found in #{db_file.upload_file_name}. Zip may be corrupted."
    else
      StashEngine::ContainerFile.insert_all(to_insert)
      db_file.update(compressed_try: db_file.compressed_try + 1)
    end

    exit
  end
end
# :nocov:
