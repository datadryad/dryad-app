module Stash
  module MerrittDownload
    Dir.glob(::File.expand_path('merritt_download/*.rb', __dir__)).sort.each(&method(:require))
  end
end
