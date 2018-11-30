# rubocop:disable Metrics/BlockLength
namespace :dev_ops do

  # use like: bundle exec rake dev_ops:processing RAILS_ENV=development
  desc 'Shows processing submissions'
  task processing: :environment do
    unless ENV['RAILS_ENV']
      puts 'RAILS_ENV must be explicitly set before running this script'
      next
    end
    in_process = StashEngine::Resource.joins(:current_resource_state).where("stash_engine_resource_states.resource_state = 'processing'")
    puts "resource_id\tuser_id\tcurrent_status\tupdated at\ttitle" if in_process.count > 0
    in_process.each do |i|
      puts "#{i.id}\t#{i.user_id}\t#{i.current_resource_state_id}\t#{i.updated_at}\t#{i.title}"
    end
  end

  desc 'update unfilled sizes'
  task fill_size: :environment do
    unless ENV['RAILS_ENV']
      puts 'RAILS_ENV must be explicitly set before running this script'
      next
    end
    StashEngine::Identifier.where(storage_size: nil).each do |i|
      lsr = i.last_submitted_resource
      next if lsr.nil? || lsr.download_uri.blank? || lsr.update_uri.blank?
      puts "Adding size to #{i}"
      ds_info = Stash::Repo::DatasetInfo.new(i)
      i.update(storage_size: ds_info.dataset_size)
    end
  end

  desc 'fill missing file sizes'
  task fill_file_size: :environment do
    unless ENV['RAILS_ENV']
      puts 'RAILS_ENV must be explicitly set before running this script'
      next
    end
    fus = StashEngine::FileUpload.where(upload_file_size: [0, nil])
    fus.each do |file_upload|
      resource = file_upload.resource
      next unless resource && resource.current_resource_state && resource.current_resource_state.resource_state == 'submitted'
      puts "updating resource #{resource.id} & #{resource.identifier}"
      ds_info = Stash::Repo::DatasetInfo.new(resource.identifier)
      file_upload.update(upload_file_size: ds_info.file_size(file_upload.upload_file_name))
    end
  end

  desc 'Update the description fields to have html content (generated from text)'
  task htmlize: :environment do
    require 'script/htmlize_descriptions'

    puts "Are you sure you want to update desciption text to html in #{Rails.env}?  (Type 'yes' to proceed, 'no' to preview.)"
    response = STDIN.gets
    if response.strip.casecmp('YES').zero?
      StashDatacite::Description.all.each do |desc|
        item = Script::HtmlizeDescriptions.new(desc.description)
        next if item.html? || desc.description.blank?
        out_html = item.text_as_html
        desc.update(description: out_html)
        puts "Updated description id: #{desc.id}"
        puts out_html
        puts ''
      end

    else
      StashDatacite::Description.all.each do |desc|
        item = Script::HtmlizeDescriptions.new(desc.description)
        next if item.html? || desc.description.blank?
        puts desc.resource.id if desc.resource
        puts item.text_as_html
        puts ''
      end
    end
  end

end
# rubocop:enable Metrics/BlockLength
