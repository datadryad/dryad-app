module Stash
  Dir.glob(File.expand_path('../stash/*.rb', __FILE__)).sort.each(&method(:require))

  # TODO: Make this configurable
  LOG_LEVEL = case ENV['STASH_ENV'].to_s.downcase
              when 'test'
                Logger::DEBUG
              when 'development'
                Logger::INFO
              else
                Logger::WARN
              end
end
