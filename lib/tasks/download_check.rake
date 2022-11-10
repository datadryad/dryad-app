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
end
