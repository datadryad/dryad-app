module StashEngine
  module CounterLog
    require 'active_support/logger'

    # rubocop:disable Style/ClassVars
    def self.logger
      mdy = Time.new.utc.strftime('%Y-%m-%d')
      path = File.join(Rails.root, 'log', "counter_#{mdy}.log")
      if File.file?(path)
        @@logger ||= ActiveSupport::Logger.new(path)
        # the following line resets the filename to new day if it's not the current day's logger, even though the old-day logger exists
        @@logger = ActiveSupport::Logger.new(path) if @@logger.instance_values['logdev'].filename != path
      else
        @@logger = ActiveSupport::Logger.new(path) # create a new logger for the first log event of the new day
        add_headers(mdy)
      end
      @@logger
    end
    # rubocop:enable Style/ClassVars

    def self.log(items) # array of items to log, will be separated by tabs
      items.flatten!
      return if items[12].blank? || items[16].blank? # do not log items without publication date or year since required for counter

      items.unshift(Time.new.utc)
      items.map! { |i| (i.respond_to?(:iso8601) ? i.iso8601 : i.to_s.strip.gsub(/\p{Cntrl}/, ' ')) }
      items.map! { |i| (i.blank? ? '-' : i) }
      logger.info(items.join("\t"))
    end

    def self.add_headers(date_string)
      l = @@logger
      l.info('#Version: 0.0.1')
      l.info("#Fields: event_time\tclient_ip\tsession_cookie_id\tuser_cookie_id\tuser_id\trequest_url\tidentifier\tfilename\tsize\tuser-agent\t" \
             "title\tpublisher\tpublisher_id\tauthors\tpublication_date\tversion\tother_id\ttarget_url\tpublication_year")
      l.info('#Software: Dryad')
      l.info("#Start-Date: #{Time.parse(date_string).iso8601}")
      l.info("#End-Date: #{(Time.parse(date_string) + 24.hours).iso8601}")
    end
  end
end
