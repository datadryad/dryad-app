#!/usr/bin/env ruby

$stdout.sync = true

require 'rubygems'
require 'bundler/setup'
require 'byebug'

# other classes for this
require_relative 'submitted_reports'
require_relative 'uploader'
require_relative 'utility_methods'

# setup variables needed
report_directory = ENV['REPORT_DIR'] || File.join(File.expand_path(__dir__), 'reports')
# ENV['TOKEN'] should be set, used in uploader class
# if ENV['REPORT_IDS'] is set then just report the IDs for our reports
# if ENV['FORCE_SUBMISSION'] is set with comma separated yyyy-mm values then those reports will be
# submitted again, even if they already appear to have been submitted

UtilityMethods.check_env_variables

force_list = UtilityMethods.force_submission_list

# retrieve all the information about already submitted reports from DataCite
submitted_reports = SubmittedReports.new
submitted_reports.process_reports

# display submitted report info and exit if that option was chosen
UtilityMethods.output_report_table_if_requested(submitted_reports)

# get the json files we have non-zero reports for and are in the correct filename format
json_files = Dir.glob(File.join(report_directory, '*.json'))
json_files.keep_if { |f| f.match(/\d{4}-\d{2}.json$/) && File.size(f) > 0 }
json_files.sort!

# go through our report files and try to submit unsubmitted/problem ones (and any you want to force submission for)
json_files.each do |json_file|
  month_year = File.basename(json_file, '.json')
  submitted_report = submitted_reports.reports[month_year]
  if UtilityMethods.needs_submission?(month_year: month_year, report_info: submitted_report, report_directory: report_directory,
                                      force_list: force_list)
    puts "adding or updating #{month_year} with #{submitted_report&.pages || 'unsubmitted'} pages"

    report_id = (submitted_report.nil? ? nil : submitted_report.id)
    uploader = Uploader.new(report_id: report_id, file_name: json_file)
    token = uploader.process
    puts "report submitted with id #{token}\n\n"
  else
    puts "skipping #{submitted_report.year_month} with #{submitted_report.pages} pages\n\n"
  end
end

exit 0
