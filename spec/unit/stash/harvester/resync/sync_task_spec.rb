require 'spec_helper'

module Stash
  module Harvester
    module Resync
      describe SyncTask do
        describe "#{Resync::ChangeDumpIndex} handling" do
          it "gets resource contents from a #{Resync::ChangeDumpIndex}"
          it 'is lazy'
        end
        describe "#{Resync::ChangeDump} handling" do
          it "gets resource contents from a #{Resync::ChangeDump}"
          it 'is lazy'
        end
        describe "#{Resync::ChangeListIndex} handling" do
          it "gets resource contents from a #{Resync::ChangeListIndex}"
          it 'is lazy'
        end
        describe "#{Resync::ChangeList} handling" do
          it "gets resource contents from a #{Resync::ChangeList}"
          it 'is lazy'
        end
        describe "#{Resync::ResourceDumpIndex} handling" do
          it "gets resource contents from a #{Resync::ResourceDumpIndex}"
          it 'is lazy'
        end
        describe "#{Resync::ResourceDump} handling" do
          it "gets resource contents from a #{Resync::ResourceDump}"
          it 'is lazy'
        end
        describe "#{Resync::ResourceListIndex} handling" do
          it "gets resource contents from a #{Resync::ResourceListIndex}"
          it 'is lazy'
        end
        describe "#{Resync::ResourceList} handling" do
          it "gets resource contents from a #{Resync::ResourceList}"
          it 'is lazy'
        end
      end
    end
  end
end
