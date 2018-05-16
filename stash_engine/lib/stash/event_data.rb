# EventData is the DataCite API for getting stats about citations and usage.
# They currently do not have totals so we need to get large swaths of data and add it up on the client side instead
# of doing it a database where it is probably easier.
module Stash
  module EventData
    Dir.glob(File.expand_path('../event_data/*.rb', __FILE__)).sort.each(&method(:require))
  end
end
