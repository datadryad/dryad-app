# Local-to-S3 conversion
# Moves files from local storage to Amazon S3
# See ticket https://github.com/CDL-Dryad/dryad-product-roadmap/issues/1079

# rubocop:disable Metrics/BlockLength
namespace :local_to_s3 do

  desc 'Copy current files from the local directory to S3'
  task copy_files: :environment do
    puts 'Starting file copy'

    # - for each resource dir
    upload_dir = File.join(Rails.root, 'uploads')
    Dir.each_child(upload_dir) do |res_dir|
      if res_dir.include?('_sfw')
        res_id = res_dir[0..-5]
        type = 'software'
      else
        res_id = res_dir
        type = 'data'
      end

      resource = StashEngine::Resource.find(res_id)
      #    - if resrouce is submitted, OR if the last activity is more than 6 months ago, skip
      if resource.submitted? || (resource.curation_activities.last.updated_at < 6.months.ago)
        puts " -- #{res_dir} --> not copied due to resource state"
        next
      end
      s3_dir = resource.s3_dir_name(type: type)
      puts " -- #{res_dir} --> #{s3_dir}"

      #    - for each file in the directory
      Dir.each_child("#{upload_dir}/#{res_dir}") do |file_name|
        s3_file = "#{s3_dir}/#{file_name}"
        #        - if it exists in s3, skip
        if Stash::Aws::S3.exists?(s3_key: s3_file)
          puts "    -- #{file_name} --> already in S3"
          next
        end
        #        - otherwise, send it
        puts "    -- #{file_name} --> #{s3_file}"
        Stash::Aws::S3.put_file(s3_key: s3_file, filename: "#{upload_dir}/#{res_dir}/#{file_name}")
      end
    end
  end

end
# rubocop:enable Metrics/BlockLength
