require 'spec_helper'

module Stash
  module Harvester
    module Resync
      describe SyncTask do
        it "works with a #{Resync::ChangeDumpIndex}"
        it "works with a #{Resync::ChangeDump}"
        it "works with a #{Resync::ChangeListIndex}"
        it "works with a #{Resync::ChangeList}"
        it "works with a #{Resync::ResourceDumpIndex}"
        it "works with a #{Resync::ResourceDump}"
        it "works with a #{Resync::ResourceListIndex}"
        it "works with a #{Resync::ResourceList}"
      end
    end
  end
end
