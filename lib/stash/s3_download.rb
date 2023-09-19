module Stash
  module S3Download
    Dir.glob(::File.expand_path('s3_download/*.rb', __dir__)).each(&method(:require))
  end
end
