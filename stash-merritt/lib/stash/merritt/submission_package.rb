module Stash
  module Merritt
    module SubmissionPackage
      Dir.glob(File.expand_path('../submission_package/*.rb', __FILE__)).sort.each(&method(:require))
    end
  end
end
