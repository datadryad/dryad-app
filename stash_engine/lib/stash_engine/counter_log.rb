module StashEngine
  module CounterLog
    require 'active_support/logger'

    # rubocop:disable Style/ClassVars
    def self.logger
      mdy = Time.new.strftime('%Y-%m-%d')
      path = File.join(Rails.root, 'log', "counter_#{mdy}.log")
      if File.file?(path)
        @@logger ||= ActiveSupport::Logger.new(path)
      else
        @@logger = ActiveSupport::Logger.new(path) # create a new logger for the first log event of the new day
        add_headers(mdy)
        @@logger
      end
    end
    # rubocop:enable Style/ClassVars

    def self.log(items) # array of items to log, will be separated by tabs
      items.flatten!
      items.unshift(Time.new)
      items.map! { |i| (i.respond_to?(:iso8601) ? i.iso8601 : i.to_s) }
      items.map! { |i| (i.blank? ? '-' : i) }
      logger.info(items.join("\t"))
    end

    def self.add_headers(date_string)
      l = @@logger
      l.info('#Version: 0.0.1')
      l.info("#Fields: event_time\tclient_ip\tsession_cookie_id\tuser_cookie_id\tuser_id\trequest_url\tidentifier\tfilename\tsize\tuser-agent\t" \
            "title\tpublisher\tpublisher_id\tauthors\tpublication_date\tversion\tother_ids\ttarget_url\tpublication_year")
      l.info('#Software: Dash')
      l.info("#Start-Date: #{Time.parse(date_string).iso8601}")
      l.info("#End-Date: #{(Time.parse(date_string) + 24.hours).iso8601}")
    end
  end
end
