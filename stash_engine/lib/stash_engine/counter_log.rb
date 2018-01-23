module StashEngine
  module CounterLog
    require 'active_support/logger'

    def self.logger
      path = File.join(Rails.root, 'log', "counter_#{Time.new.strftime("%Y-%m-%d")}.log")
      if File.file?(path)
        @@logger ||= ActiveSupport::Logger.new(path)
      else
        @@logger = ActiveSupport::Logger.new(path) # create a new logger for the first log even of the new day
      end
    end

    def self.log(items) #array of items to log, will be separated by tabs
      items.flatten!
      items.unshift(Time.new)
      items.map!{|i| (i.respond_to?(:iso8601) ? i.iso8601 : i.to_s ) }
      self.logger.info(items.join("\t"))
    end
  end
end