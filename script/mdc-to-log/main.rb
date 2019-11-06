#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'
require 'byebug'
require 'sqlite3'
require 'active_record'
require 'time'

filename=ARGV.first

ActiveRecord::Base.logger = Logger.new(STDERR)
ActiveRecord::Base.logger.level = :warn
ActiveRecord::Base.establish_connection(
    adapter: 'sqlite3',
    database: filename
)

class LogItem < ActiveRecord::Base
  self.table_name = 'logitem'
  belongs_to :metadata_item
end

class MetadataItem < ActiveRecord::Base
  self.table_name = 'metadataitem'
  has_many :log_items
  has_many :authors
end

class Author < ActiveRecord::Base
  self.table_name = 'metadataauthor'
  belongs_to :metadata_item
end

out_fn = "#{File.basename(filename, '.sqlite3')}.log"

records = LogItem.joins(:metadata_item)
puts 'Writing log'

File.open(out_fn, "w:UTF-8") do |f|
  records.each_with_index do |r, idx|
    puts "Processing record #{idx}" if idx % 10000 == 0
    out = [
      r.event_time&.iso8601,
      r.client_ip,
      r.session_cookie_id,
      r.user_cookie_id,
      r.user_id,
      r.request_url,
      r.identifier,
      r.filename,
      r.size,
      r.user_agent,
      r&.metadata_item&.title,
      r&.metadata_item&.publisher,
      r&.metadata_item&.publisher_id,
      r&.metadata_item&.authors&.map(&:author_name)&.join('|'),
      r&.metadata_item&.publication_date,
      r&.metadata_item&.version,
      r&.metadata_item&.other_id,
      r&.metadata_item&.target_url,
      r&.metadata_item&.publication_year
    ]
    f.write("#{out.map{|i| (i.blank? ? '-' : i) }.join("\t")}\n")
  end
end
