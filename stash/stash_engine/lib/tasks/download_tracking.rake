namespace :download_tracking do

  # because of our privacy policy we don't keep most logs or log-like info for more than 60 days as I understand it
  desc 'cleanup download history'
  task cleanup: :environment do
    # Reset downloads from table that show longer than 24 hours in progress, since most likely the status is wrong.
    # If the server is shut down in a disorderly way, the 'ensure' clause may not run to close out download info.
    # It seems to happen quite rarely (also leaves stray download files in our EFS mount in the rare cases).
    StashEngine::DownloadHistory.downloading.where('created_at < ?', 1.day.ago).update_all(state: 'finished')

    # clean up information older than 60 days to comply with privacy and no callbacks
    StashEngine::DownloadHistory.where('created_at < ?', 60.days.ago).delete_all
    puts "#{Time.new.iso8601} Finished DownloadHistory cleanup"
  end

end
