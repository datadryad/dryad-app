module UtilityMethods
  def self.needs_submission?(month_year:, report_directory:, force_list:, report_info: nil)
    # submit if it is being forced or no report info or no pages of results
    return true if force_list.include?(month_year) || report_info.nil? || report_info.pages.nil? || report_info.pages == 0

    # otherwise check the number of pages of results against the json file size. I did a quick analysis
    # and the filesize-bytes/pages hovered around 10,000 for most validly submitted reports.
    # Seemed to always be in the range of 8,000 up to about 20,000 bytes of json per page of DataCite results
    # So if the number of bytes/page is > 50,000 then something is probably really wrong.
    filesize = File.size(File.join(report_directory, "#{month_year}.json"))
    return true if (filesize / report_info.pages) > 50_000

    false
  end

  def self.check_env_variables
    return unless ENV['REPORT_IDS'].nil? && (ENV['TOKEN'].nil? || ENV['REPORT_DIR'].nil?)

    puts 'You must set environment variables for the TOKEN and REPORT_DIR to upload to DataCite.'
    puts 'Optional environment variables:'
    puts "\tREPORT_IDS -- if set, only reports the yyyy-mm and ids that have been sent to DataCite."
    puts "\tFORCE_SUBMISSION may be set with a comma separated list of yyyy-mm values and those reports"
    puts "\twill be sent again, even if they appear to have already been submitted successfully."
    exit(1)
  end

  def self.output_report_table_if_requested(submitted_reports)
    return unless ENV['REPORT_IDS']

    puts 'Information about submitted months in tab separated format.'
    puts "year-month\tresults_pages\tid"
    submitted_reports.reports.values.sort { |a, b| a.year_month <=> b.year_month }.each do |report|
      puts "#{report.year_month}\t#{report.pages}\t#{report.id}"
    end
    exit 0
  end

  def self.force_submission_list
    return [] if ENV['FORCE_SUBMISSION'].nil?

    ENV['FORCE_SUBMISSION'].split(',').map(&:strip)
  end
end
