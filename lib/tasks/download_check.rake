# :nocov:
require_relative 'download_check/merritt'

namespace :download_check do

  # checks one download from each of the published datasets to see if they seem downloadable
  desc "check merritt datasets to be sure they're able to download"
  task merritt: :environment do
    sql = 'SELECT * FROM stash_engine_identifiers ids ' \
          'WHERE ids.pub_state = "published" ' \
          'AND id IN (SELECT DISTINCT identifier_id FROM stash_engine_resources WHERE tenant_id = "dataone")'

    ids = StashEngine::Identifier.find_by_sql(sql)
    dl_merritt = Tasks::DownloadCheck::Merritt.new(identifiers: ids)
    dl_merritt.check_a_download
    dl_merritt.output_csv(filename: 'dataone.csv')
  end

  task merritt_all_latest_public: :environment do
    ids = StashEngine::Identifier.publicly_viewable
    # these can produce errors for testing
    # ids = StashEngine::Identifier.where(id: [113, 151, 210, 2108, 2143, 2150, 5149, 5186])
    dl_merritt = Tasks::DownloadCheck::Merritt.new(identifiers: ids)
    dl_merritt.check_all_files
    dl_merritt.output_csv(filename: 'all_merritt_public.csv')
    puts 'wrote all_merritt_public.csv'
  end

  desc 'presents a list of files that have incorrect deposit states in our database compared where Merritt deposited them'
  task check_created_s3: :environment do
    # identifiers with some submitted resources
    se_ids = StashEngine::Identifier.joins( resources: :resource_states)
                                    .where( "stash_engine_resource_states.resource_state = 'submitted'").distinct

    my_filename = "s3_check_#{Rails.env}_#{Time.new.strftime('%Y-%m-%d_%H:%M:%S')}.csv"

    CSV.open(my_filename, 'w') do |csv|
      csv << %w(identifier_id identifier_doi resource_id
                file_id filename expected_version expected_size
                before_version before_size
                after_version after_size)
      se_ids.each_with_index do |se_id, idx|
        se_id.resources.each do |res|
          next unless res.current_resource_state.resource_state == 'submitted'

          d_files = res.data_files.newly_created
          d_files.each do |df|
            s3_check = Tasks::DownloadCheck::S3Check.new(file: df)
            s3_chk = s3_check.check_file
            next if s3_chk.nil?

            csv << [se_id.id, se_id.identifier, res.id,
                    df.id, df.upload_file_name, s3_check.mrt_version, df.upload_file_size,
                    s3_chk[:before][0], s3_chk[:before][1],
                    s3_chk[:after][0], s3_chk[:after][1]]
            # puts "#{se_id.id}, #{se_id.identifier}, #{res.id}, #{df.id}, #{df.upload_file_name}, #{s3_check.mrt_version}, #{s3_chk[:before]}, #{s3_chk[:after]}"
            # puts "ident: #{se_id.identifier}, res_id: #{res.id}, file_id: #{df.id}, name: #{df.upload_file_name}, chk: #{s3_chk}"
          end
        end
        puts "#{idx + 1}/#{se_ids.count} identifiers checked" if (idx + 1) % 100 == 0
      end
    end
    puts "wrote #{my_filename}"
  end
end
# :nocov:
