require 'spec_helper'

# TODO: Rewrite this to trust resync-client more, be more unit-y
module Stash
  module Harvester
    module Resync
      describe SyncTask do
        before(:each) do
          @resync_client = instance_double(::Resync::Client)
          expect(::Resync::Client).to receive(:new) { @resync_client }
          allow(@resync_client).to receive(:client) { @resync_client }

          @capability_list = instance_double(::Resync::CapabilityList)
          @cap_list_uri = URI('http://example.org/capability-list.xml')
          expect(@resync_client).to receive(:get_and_parse).with(@cap_list_uri) { @capability_list }

          @sync_task = SyncTask.new(capability_list_uri: @cap_list_uri)
        end

        describe "#{::Resync::ChangeDumpIndex} handling" do
          it "gets resource contents from a #{::Resync::ChangeDumpIndex}"
          it 'returns an Enumerator::Lazy'
        end
        describe "#{::Resync::ChangeDump} handling" do
          it "gets resource contents from a #{::Resync::ChangeDump}"
          it 'returns an Enumerator::Lazy'
        end
        describe "#{::Resync::ChangeListIndex} handling" do
          it "gets resource contents from a #{::Resync::ChangeListIndex}"
          it 'returns an Enumerator::Lazy'
        end
        describe "#{::Resync::ChangeList} handling" do
          it "gets resource contents from a #{::Resync::ChangeList}"
          it 'returns an Enumerator::Lazy'
        end
        describe "#{::Resync::ResourceDumpIndex} handling" do
          it "gets resource contents from a #{::Resync::ResourceDumpIndex}"
          it 'returns an Enumerator::Lazy'
        end

        describe "#{::Resync::ResourceDump} handling" do
          before(:each) do
            @resource_dump = ::Resync::XMLParser.parse(File.new('spec/data/resync/dumps/resourcedump1/resourcedump1.xml'))
            expect(@capability_list).to receive(:resource_dump) { @resource_dump }
          end

          it "gets resource contents from a #{::Resync::ResourceDump}" do
            @resource_dump.client_delegate = @resync_client

            resource_contents = []
            (1..3).each do |p|
              dir = "spec/data/resync/dumps/resourcedump1/part#{p}"
              file = "#{dir}.zip"
              expect(@resync_client).to receive(:download_to_temp_file).with(URI("http://example.com/resourcedump1/part#{p}.zip")) { file }
              ((p * 2 - 1)..(p * 2)).each do |r|
                resource_contents << File.read("#{dir}/res#{r}")
              end
            end

            downloaded = @sync_task.download
            downloaded_array = downloaded.to_a
            downloaded_array.each_with_index do |rc, i|
              expect(rc.content).to eq(resource_contents[i])
            end
          end

          it 'returns an Enumerator::Lazy' do
            downloaded = @sync_task.download
            expect(downloaded).to be_a(Enumerator::Lazy)
          end
        end

        describe "#{::Resync::ResourceListIndex} handling" do
          before(:each) do
            expect(@capability_list).to receive(:resource_dump)

            @resource_list_index = ::Resync::XMLParser.parse(File.new('spec/data/resync/resource-list-index.xml'))
            @resource_list_index.client_delegate = @resync_client
            expect(@capability_list).to receive(:resource_list) { @resource_list_index }

            @resource_lists = Array.new(2) do |i|
              resource_list_uri = URI("http://example.com/resourcelist#{i + 1}.xml")
              resource_list = ::Resync::XMLParser.parse(File.new("spec/data/resync/resource-list-#{i + 1}.xml"))
              allow(@resync_client).to receive(:get_and_parse).with(resource_list_uri) { resource_list }
              resource_list
            end

            @all_resources = @resource_lists.flat_map(&:resources)

            allow(@resync_client).to receive(:get_and_parse).with(@cap_list_uri) { @capability_list }
          end

          it "gets resource contents from a #{::Resync::ResourceListIndex}" do
            downloaded = @sync_task.download
            downloaded_array = downloaded.to_a
            @all_resources.each_with_index do |r, i|
              expect(downloaded_array[i].uri).to eq(r.uri)
            end
          end

          it 'returns an Enumerator::Lazy' do
            downloaded = @sync_task.download
            expect(downloaded).to be_a(Enumerator::Lazy)
          end
        end

        describe "#{::Resync::ResourceList} handling" do
          before(:each) do
            @resource_list = instance_double(::Resync::ResourceList)
            @all_resources = [
              ::Resync::Resource.new(uri: 'http://example.org/res1'),
              ::Resync::Resource.new(uri: 'http://example.org/res2')
            ]
            expect(@resource_list).to receive(:all_resources) { @all_resources.lazy }

            expect(@capability_list).to receive(:resource_dump)
            expect(@capability_list).to receive(:resource_list) { @resource_list }
          end

          it "gets resource contents from a #{::Resync::ResourceList}" do
            downloaded = @sync_task.download
            downloaded_array = downloaded.to_a
            @all_resources.each_with_index do |r, i|
              expect(downloaded_array[i].uri).to eq(r.uri)
            end
          end

          it 'returns an Enumerator::Lazy' do
            downloaded = @sync_task.download
            expect(downloaded).to be_a(Enumerator::Lazy)
          end
        end
      end
    end
  end
end
