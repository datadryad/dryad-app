class ArchiveAnalyzerJob < Submission::BaseJob
  include Sidekiq::Worker
  include StashEngine::ApplicationHelper
  sidekiq_options queue: :archive_analyzer, retry: 1, lock: :until_and_while_executing

  def perform(file_id)
    start = Time.current
    file = StashEngine::DataFile.find(file_id)
    return if !file.archive? || %w[created copied].exclude?(file.file_state)

    if file.copied?
      puts "Copying container_contents for #{file.upload_file_name} (id: #{file.id}, " \
           "resource_id: #{file.resource_id}) from previous unchanged file"

      file.populate_container_files_from_last
      return
    end

    puts "Updating container_contents for #{file.upload_file_name} (id: #{file.id}, " \
         "resource_id: #{file.resource_id})"

    to_insert = Tasks::Compressed::Info.files(db_file: file).map do |file_info|
      next if file_info[:path].include?('__MACOSX') || file_info[:path].end_with?('.DS_Store')

      { data_file_id: file.id, path: file_info[:path], mime_type: file_info[:mime_type], size: file_info[:size] }
    end.compact.first(1000) # only do 1000 if there are more than that, they are probably repetitive

    if to_insert.empty?
      puts "  No files found in #{file.upload_file_name}. Zip may be corrupted."
    else
      file.container_files.delete_all
      StashEngine::ContainerFile.insert_all(to_insert)
    end
    puts "Finished for #{file.upload_file_name} (id: #{file.id}, size: #{filesize(file.upload_file_size)}, in #{Time.current - start} seconds)"
  ensure
    file.update(compressed_try: file.compressed_try + 1)
  end
end
