#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'
require 'byebug'
require 'pp'

# other classes for this
require_relative 'submitted_report_info'
require_relative 'uploader'

# setup variables needed
@report_directory = ENV['REPORT_DIR'] || File.join(File.expand_path(__dir__), 'reports')
# ENV['TOKEN'] should be set, used in uploader class
# if ENV['REPORT_IDS'] is set then just report the IDs for our reports

if ENV['REPORT_IDS'].nil? && (ENV['TOKEN'].nil? || ENV['REPORT_DIR'].nil?)
  puts 'You must set environment variables for the TOKEN and REPORT_DIR to upload to DataCite'
  exit(1)
end

# get the json files we have non-zero reports for and are in the correct filename format
@json_files = Dir.glob(File.join(@report_directory, '*.json'))
@json_files.keep_if { |f| f.match(/\d{4}-\d{2}.json$/) && File.size(f) > 0 }
@json_files.sort!


@submitted_reports = SubmittedReports.new
@submitted_reports.process_reports

exit 0 unless ENV['REPORT_IDS'].nil?

@json_files.each do |json_file|
  basename = File.basename(json_file, '.json')
  submitted_report = @submitted_reports.reports[basename]
  if submitted_report.nil? || ( submitted_report.pages < 200 && submitted_report.year_month > '2012-12') ||
      ( submitted_report.pages < 10 && submitted_report.year_month < '2013-01')
    puts "adding or updating #{basename} with #{submitted_report&.pages || 'unsubmitted'} pages"

    report_id = ( submitted_report.nil? ? nil : submitted_report.id )
    uploader = Uploader.new(report_id: report_id, file_name: json_file)
    token = uploader.process
    puts "report submitted with id #{token}"
    puts ''
  else
    puts "skipping #{submitted_report.year_month} with #{submitted_report.pages} pages"
    puts ''
  end
end

exit 0
