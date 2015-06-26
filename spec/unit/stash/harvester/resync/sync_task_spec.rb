require 'spec_helper'

module Stash
  module Harvester
    module Resync
      describe SyncTask do
        before(:each) do
          @resync_client = instance_double(::Resync::Client)
          expect(::Resync::Client).to receive(:new) { @resync_client }

          @capability_list = instance_double(::Resync::CapabilityList)
          @cap_list_uri = URI('http://example.org/capability-list.xml')
          expect(@resync_client).to receive(:get_and_parse).with(@cap_list_uri) { @capability_list }
        end

        describe "#{::Resync::ChangeDumpIndex} handling" do
          it "gets resource contents from a #{::Resync::ChangeDumpIndex}"
          it 'is lazy'
        end
        describe "#{::Resync::ChangeDump} handling" do
          it "gets resource contents from a #{::Resync::ChangeDump}"
          it 'is lazy'
        end
        describe "#{::Resync::ChangeListIndex} handling" do
          it "gets resource contents from a #{::Resync::ChangeListIndex}"
          it 'is lazy'
        end
        describe "#{::Resync::ChangeList} handling" do
          it "gets resource contents from a #{::Resync::ChangeList}"
          it 'is lazy'
        end
        describe "#{::Resync::ResourceDumpIndex} handling" do
          it "gets resource contents from a #{::Resync::ResourceDumpIndex}"
          it 'is lazy'
        end
        describe "#{::Resync::ResourceDump} handling" do
          it "gets resource contents from a #{::Resync::ResourceDump}"
          it 'is lazy'
        end
        describe "#{::Resync::ResourceListIndex} handling" do
          it "gets resource contents from a #{::Resync::ResourceListIndex}"
          it 'is lazy'
        end
        describe "#{::Resync::ResourceList} handling" do
          it "gets resource contents from a #{::Resync::ResourceList}" do
            resource_list = instance_double(::Resync::ResourceList)
            all_resources = [
              ::Resync::Resource.new(uri: 'http://example.org/res1'),
              ::Resync::Resource.new(uri: 'http://example.org/res2')
            ]
            expect(resource_list).to receive(:all_resources) { all_resources.lazy }

            expect(@capability_list).to receive(:resource_dump)
            expect(@capability_list).to receive(:resource_list) { resource_list }
            sync_task = SyncTask.new(capability_list_uri: @cap_list_uri)
            downloaded = sync_task.download.to_a
            all_resources.each_with_index do |r, i|
              expect(downloaded[i].uri).to eq(r.uri)
            end
          end
          it 'is lazy'
        end
      end
    end
  end
end
