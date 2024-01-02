#!/usr/bin/env ruby
# call like ./cdl_logs.rb -a cdl -f dryad_raw_events_20231101_sorted.csv to import some CDL logs

require 'bundler/setup'
Bundler.require
require "active_record"
require_relative 'create_counter_table'
require_relative 'counter_log'
require 'optparse'
require 'uri'
require 'csv'
require 'byebug'

ActiveRecord::Base.establish_connection(
  adapter:  'sqlite3',
  database: 'cdl_logs.sqlite3.db'
)

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: 'cdl_logs.sqlite3.db')
CreateCounterTable.migrate(:up) unless ActiveRecord::Base.connection.table_exists? 'counter_log'

VIEW = Regexp.new(%w(
  ^\/api\/v2\/datasets\/[^\/]+$
  ^\/api\/v2\/versions\/\d+$/
  ^\/stash\/dataset\/\S+$
  ^\/stash\/landing\/show$
  ^\/stash\/data_paper\/\S+$
  ^\/resource\/doi:[^/]+/dryad[^/]+$
).join('|'))

DOWNLOAD = Regexp.new(%w(
  ^\/api\/v2\/datasets\/[^\/]+\/download$
  ^\/api\/v2\/versions\/\d+\/download$
  ^\/api\/v2\/downloads\/\d+$
  ^\/stash\/downloads\/download_resource\/\d+$
  ^\/stash\/downloads\/file_download\/\d+$
  ^\/stash\/downloads\/file_stream\/\d+$
  ^\/stash\/downloads\/async_request\/\d+$
  ^\/stash\/downloads\/assembly_status\/\d+$
  ^\/stash\/share/\S+$
  ^\/stash\/downloads\/zip_assembly_info\/\d+$
  ^\/resource\/doi:[^/]+\/dryad[^/]+/.+$
).join('|'))

def populate_cdl_file(file:)
  File.readlines('counter_2023-11-01.log_combined').each_with_index do |line, i|
    next if line.blank? || line.start_with?('#')

    parts = line.split("\t")
    path = URI(parts[5]).path

    hit_type = 'unknown'
    hit_type = 'download' if path.match?(DOWNLOAD)
    hit_type = 'view' if path.match?(VIEW)

    CounterLog.create(
      time: parts[0],
      ip: parts[1],
      url: parts[5],
      doi: parts[6],
      user_agent: parts[9],
      hit_type: hit_type,
      matched: false)
    puts "Crunched #{i+1} lines" if ((i+1) % 5000).zero?
  end
end

# it looks like
# "timestamp","metric_name","repo_id", "user_id", "session_id", "url", "pid"
# "2023-11-01 15:32:20.721","view","da-80l49bsf",25990524582826763,3082643891120137357,"https://datadryad.org/stash/dataset/doi:10.6078/D1MS3X","10.6078/D1MS3X"
def match_datacite_entries(file:)
  count = 0
  matched_count = 0

  CSV.foreach((file), headers: true, encoding: "bom|utf-8", quote_char: '"', col_sep: ',') do |row|
    the_time = Time.find_zone("UTC").parse(row['timestamp'])
    doi = "doi:#{row['pid']}"
    metric = row['metric_name']

    log_entry = best_match(doi: doi, time: the_time, metric: metric)

    count += 1
    matched_count += 1 unless log_entry.nil?
    puts "Processed #{count} entries, #{matched_count} matched" if (count % 500).zero?

    if log_entry.nil?
      puts "No match for #{doi} at #{the_time} for #{metric}"
      next
    end

    log_entry.update(matched: true)
  end
end

def best_match(doi:, time:, metric:)
  # find the best match for the doi, time, and metric
  # if there is a match, mark it as matched and return it
  # if there is no match, return nil
  items = CounterLog.where(doi: doi, hit_type: metric).where('time BETWEEN ? AND ?', time - 60.seconds, time + 30.seconds)
  return nil if items.blank?

  # if there is only one, then use it
  return items.first if items.length == 1

  # if there are more than one, then use the one with the closest time
  items.sort_by { |item| (item.time - time).abs }.first
end


options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: cdl_logs.rb --file FILE --action [cdl|datacite]"

  opts.on("-f", "--file FILE", "File to process") do |f|
    options[:file] = f
  end

  opts.on("-a", "--action [cdl|datacite]", "Action to perform") do |a|
    options[:action] = a
  end
end.parse!

if options[:action] == 'cdl'
  populate_cdl_file(file: options[:file])
elsif options[:action] == 'datacite'
  match_datacite_entries(file: options[:file])
end
