module Stash
  module MerrittDeposit
    Dir.glob(File.expand_path('merritt_deposit/*.rb', __dir__)).each(&method(:require))
  end
end
