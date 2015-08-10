require 'spec_helper'

# TODO: Rewrite this to trust resync-client more, be more unit-y
# TODO: share more examples
module Stash
  module Harvester
    # noinspection RubyTooManyInstanceVariablesInspection
    module Resync # rubocop:disable Metrics/ModuleLength
      describe ResyncHarvestTask do

        describe '#new' do
          it 'accepts a valid "from" datestamp' do
            time = Time.new.utc
            sync_task = ResyncHarvestTask.new(config: ResyncSourceConfig.new(capability_list_url: 'http://example.org/cap_list.xml'), from_time: time)
            expect(sync_task.from_time).to eq(time)
          end

          it 'accepts a valid "until" datestamp' do
            time = Time.new.utc
            sync_task = ResyncHarvestTask.new(config: ResyncSourceConfig.new(capability_list_url: 'http://example.org/cap_list.xml'), until_time: time)
            expect(sync_task.until_time).to eq(time)
          end

          it 'rejects datestamps that would create an invalid range' do
            epoch = Time.at(0).utc
            now = Time.new.utc

            expect { ResyncHarvestTask.new(config: ResyncSourceConfig.new(capability_list_url: 'http://example.org/cap_list.xml'), from_time: now, until_time: epoch) }.to raise_error(RangeError)
          end

          it 'rejects non-UTC datestamps' do
            non_utc = Time.new(2002, 10, 31, 2, 2, 2, '+02:00')
            expect { ResyncHarvestTask.new(config: ResyncSourceConfig.new(capability_list_url: 'http://example.org/cap_list.xml'), from_time: non_utc) }.to raise_error(ArgumentError)
            expect { ResyncHarvestTask.new(config: ResyncSourceConfig.new(capability_list_url: 'http://example.org/cap_list.xml'), until_time: non_utc) }.to raise_error(ArgumentError)
          end

          it 'requires a config' do
            # noinspection RubyArgCount
            expect { ResyncHarvestTask.new }.to raise_error(ArgumentError)
          end
        end

        describe '#download' do

          before(:each) do
            @resync_client = instance_double(::Resync::Client)
            expect(::Resync::Client).to receive(:new) { @resync_client }
            allow(@resync_client).to receive(:client) { @resync_client }

            @capability_list = instance_double(::Resync::CapabilityList)
            @cap_list_uri = URI('http://example.org/capability-list.xml')
            expect(@resync_client).to receive(:get_and_parse).with(@cap_list_uri) { @capability_list }
          end

          describe "#{::Resync::ResourceList} handling" do
            before(:each) do
              @sync_task = ResyncHarvestTask.new(config: ResyncSourceConfig.new(capability_list_url: @cap_list_uri))
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
              downloaded = @sync_task.harvest_records
              downloaded_array = downloaded.to_a
              @all_resources.each_with_index do |r, i|
                expect(downloaded_array[i].identifier).to eq(r.uri.to_s)
              end
            end

            it 'returns an Enumerator::Lazy' do
              downloaded = @sync_task.harvest_records
              expect(downloaded).to be_a(Enumerator::Lazy)
            end
          end

          describe "#{::Resync::ResourceDumpIndex} handling" do
            before(:each) do
              @resource_dump_index = ::Resync::XMLParser.parse(File.new('spec/data/resync/dumps/resourcedumpindex.xml'))
              expect(@capability_list).to receive(:resource_dump) { @resource_dump_index }
              @sync_task = ResyncHarvestTask.new(config: ResyncSourceConfig.new(capability_list_url: @cap_list_uri))
            end
            it "gets resource contents from a #{::Resync::ResourceDumpIndex}" do
              @resource_dump_index.client_delegate = @resync_client

              resource_contents = []
              (1..2).each do |d|
                dump = ::Resync::XMLParser.parse(File.new("spec/data/resync/dumps/dump#{d}/resourcedump#{d}.xml"))
                dump.client_delegate = @resync_client
                expect(@resync_client).to receive(:get_and_parse).with(URI("http://example.org/resourcedump#{d}/resourcedump#{d}.xml")) { dump }

                (1..3).each do |p|
                  dir = "spec/data/resync/dumps/dump#{d}/part#{p}"
                  file = "#{dir}.zip"
                  expect(@resync_client).to receive(:download_to_temp_file).with(URI("http://example.org/resourcedump#{d}/part#{p}.zip")) { file }
                  ((p * 2 - 1)..(p * 2)).each do |r|
                    resource_contents << File.read("#{dir}/res#{r}")
                  end
                end
              end

              downloaded = @sync_task.harvest_records
              downloaded_array = downloaded.to_a
              resource_contents.each_with_index do |rc, i|
                expect(downloaded_array[i].content).to eq(rc)
              end
            end

            it 'returns an Enumerator::Lazy' do
              downloaded = @sync_task.harvest_records
              expect(downloaded).to be_a(Enumerator::Lazy)
            end
          end

          describe "#{::Resync::ResourceDump} handling" do
            before(:each) do
              @resource_dump = ::Resync::XMLParser.parse(File.new('spec/data/resync/dumps/dump1/resourcedump1.xml'))
              expect(@capability_list).to receive(:resource_dump) { @resource_dump }
              @sync_task = ResyncHarvestTask.new(config: ResyncSourceConfig.new(capability_list_url: @cap_list_uri))
            end

            it "gets resource contents from a #{::Resync::ResourceDump}" do
              @resource_dump.client_delegate = @resync_client

              resource_contents = []
              (1..3).each do |p|
                dir = "spec/data/resync/dumps/dump1/part#{p}"
                file = "#{dir}.zip"
                expect(@resync_client).to receive(:download_to_temp_file).with(URI("http://example.org/resourcedump1/part#{p}.zip")) { file }
                ((p * 2 - 1)..(p * 2)).each do |r|
                  resource_contents << File.read("#{dir}/res#{r}")
                end
              end

              downloaded = @sync_task.harvest_records
              downloaded_array = downloaded.to_a
              resource_contents.each_with_index do |rc, i|
                expect(downloaded_array[i].content).to eq(rc)
              end
            end

            it 'returns an Enumerator::Lazy' do
              downloaded = @sync_task.harvest_records
              expect(downloaded).to be_a(Enumerator::Lazy)
            end
          end

          describe "#{::Resync::ResourceListIndex} handling" do
            before(:each) do
              @sync_task = ResyncHarvestTask.new(config: ResyncSourceConfig.new(capability_list_url: @cap_list_uri))

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
              downloaded = @sync_task.harvest_records
              downloaded_array = downloaded.to_a
              @all_resources.each_with_index do |r, i|
                expect(downloaded_array[i].identifier).to eq(r.uri.to_s)
              end
            end

            it 'returns an Enumerator::Lazy' do
              downloaded = @sync_task.harvest_records
              expect(downloaded).to be_a(Enumerator::Lazy)
            end
          end

          describe "#{::Resync::ChangeList} handling" do
            before(:each) do
              allow(@capability_list).to receive(:change_dump)

              @change_list = ::Resync::XMLParser.parse(File.new('spec/data/resync/change-list-1.xml'))
              expect(@capability_list).to receive(:change_list) { @change_list }
              @change_list.client_delegate = @resync_client
            end

            it "gets resource contents from a #{::Resync::ChangeList}" do
              resource_contents = []
              (1..2).each do |r|
                contents = "content of resource #{r}"
                expect(@resync_client).to receive(:get).with(URI("http://example.com/res#{r}")) { contents }
                resource_contents << contents
              end

              @sync_task = ResyncHarvestTask.new(config: ResyncSourceConfig.new(capability_list_url: @cap_list_uri), from_time: Time.utc(2012), until_time: Time.utc(2014))
              downloaded = @sync_task.harvest_records
              downloaded_array = downloaded.to_a
              resource_contents.each_with_index do |rc, i|
                expect(downloaded_array[i].content).to eq(rc)
              end
            end

            it 'filters by modified_time' do
              contents = 'content of resource 1'
              expect(@resync_client).to receive(:get).once.with(URI('http://example.com/res1')) { contents }

              @sync_task = ResyncHarvestTask.new(config: ResyncSourceConfig.new(capability_list_url: @cap_list_uri), from_time: Time.utc(2012, 12, 31), until_time: Time.utc(2013, 1, 1, 12))
              downloaded = @sync_task.harvest_records
              downloaded_array = downloaded.to_a
              expect(downloaded_array.size).to eq(1)
              expect(downloaded_array[0].content).to eq(contents)
            end

            it 'returns an Enumerator::Lazy' do
              @sync_task = ResyncHarvestTask.new(config: ResyncSourceConfig.new(capability_list_url: @cap_list_uri), from_time: Time.utc(2012), until_time: Time.utc(2014))
              downloaded = @sync_task.harvest_records
              expect(downloaded).to be_a(Enumerator::Lazy)
            end
          end

          describe "#{::Resync::ChangeListIndex} handling" do
            before(:each) do
              allow(@capability_list).to receive(:change_dump)

              @change_list_index = ::Resync::XMLParser.parse(File.new('spec/data/resync/change-list-index.xml'))
              expect(@capability_list).to receive(:change_list) { @change_list_index }
              @change_list_index.client_delegate = @resync_client
              @all_resources = []
              (1..3).each do |i|
                change_list_uri = URI("http://example.com/2013010#{i}-changelist.xml")
                change_list = ::Resync::XMLParser.parse(File.new("spec/data/resync/change-list-#{i}.xml"))
                allow(@resync_client).to receive(:get_and_parse).with(change_list_uri) { change_list }
                change_list.resources.each do |r|
                  @all_resources << r
                end
              end
            end

            it "gets resource contents from a #{::Resync::ChangeListIndex}" do
              @sync_task = ResyncHarvestTask.new(config: ResyncSourceConfig.new(capability_list_url: @cap_list_uri), from_time: Time.utc(2012, 12, 31), until_time: Time.utc(2014, 1, 1))

              resource_contents = []
              @all_resources.each do |r|
                content = "content of #{r.uri}"
                expect(r).to receive(:get) { content }
                resource_contents << content
              end

              downloaded = @sync_task.harvest_records
              downloaded_array = downloaded.to_a
              resource_contents.each_with_index do |rc, i|
                expect(downloaded_array[i].content).to eq(rc)
              end
            end

            it 'filters by time range' do
              @sync_task = ResyncHarvestTask.new(config: ResyncSourceConfig.new(capability_list_url: @cap_list_uri), from_time: Time.utc(2012, 12, 31), until_time: Time.utc(2013, 1, 2, 12))

              resource_contents = []
              @all_resources.each do |r|
                content = "content of #{r.uri}"
                allow(r).to receive(:get) { content }
                resource_contents << content
              end

              downloaded = @sync_task.harvest_records
              downloaded_array = downloaded.to_a
              expect(downloaded_array.size).to eq(3)
              resource_contents[0, 3].each_with_index do |rc, i|
                expect(downloaded_array[i].content).to eq(rc)
              end
            end

            it 'returns an Enumerator::Lazy' do
              @sync_task = ResyncHarvestTask.new(config: ResyncSourceConfig.new(capability_list_url: @cap_list_uri), from_time: Time.utc(2012, 12, 31), until_time: Time.utc(2014, 1, 1))
              downloaded = @sync_task.harvest_records
              expect(downloaded).to be_a(Enumerator::Lazy)
            end
          end

          describe "#{::Resync::ChangeDumpIndex} handling" do

            before(:each) do
              @from_time = Time.utc(2012)
              @until_time = Time.utc(2014)
              @dump = instance_double(::Resync::ChangeDumpIndex)
              expect(@capability_list).to receive(:change_dump) { @dump }

              @zip_packages = Array.new(3) { instance_double(::Resync::Client::Zip::ZipPackage) }
              expect(@dump).to receive(:all_zip_packages).with(in_range: @from_time..@until_time) { @zip_packages.lazy }
              @sync_task = ResyncHarvestTask.new(config: ResyncSourceConfig.new(capability_list_url: @cap_list_uri), from_time: @from_time, until_time: @until_time)
            end

            it "gets resource contents from a #{::Resync::ChangeDump}" do
              resource_contents = []
              @zip_packages.each do |zp|
                bitstreams = Array.new(3) { instance_double(::Resync::Client::Zip::Bitstream) }
                bitstreams.each do |bs|
                  index = resource_contents.size
                  content = "contents of resource #{index}"
                  resource_contents << content
                  resource = ::Resync::Resource.new(uri: URI("http://example.com/change#{index}"))
                  allow(resource).to receive(:bitstream) { bs }
                  allow(bs).to receive(:resource) { resource }
                  allow(bs).to receive(:content) { content }
                end
                expect(zp).to receive(:bitstreams) { bitstreams }
              end

              downloaded = @sync_task.harvest_records
              downloaded_array = downloaded.to_a
              expect(downloaded_array.size).to eq(resource_contents.size)
              downloaded_array.each_with_index do |rc, i|
                expect(rc.content).to eq(resource_contents[i])
              end
            end

            it 'returns an Enumerator::Lazy' do
              expect(@sync_task.harvest_records).to be_a(Enumerator::Lazy)
            end
          end

          describe "#{::Resync::ChangeDump} handling" do

            before(:each) do
              @from_time = Time.utc(2012)
              @until_time = Time.utc(2014)
              @dump = instance_double(::Resync::ChangeDump)
              expect(@capability_list).to receive(:change_dump) { @dump }

              @zip_packages = Array.new(3) { instance_double(::Resync::Client::Zip::ZipPackage) }
              expect(@dump).to receive(:all_zip_packages).with(in_range: @from_time..@until_time) { @zip_packages.lazy }
              @sync_task = ResyncHarvestTask.new(config: ResyncSourceConfig.new(capability_list_url: @cap_list_uri), from_time: @from_time, until_time: @until_time)
            end

            it "gets resource contents from a #{::Resync::ChangeDump}" do
              resource_contents = []
              @zip_packages.each do |zp|
                bitstreams = Array.new(3) { instance_double(::Resync::Client::Zip::Bitstream) }
                bitstreams.each do |bs|
                  index = resource_contents.size
                  content = "contents of resource #{index}"
                  resource_contents << content
                  resource = ::Resync::Resource.new(uri: URI("http://example.com/change#{index}"))
                  allow(resource).to receive(:bitstream) { bs }
                  allow(bs).to receive(:resource) { resource }
                  allow(bs).to receive(:content) { content }
                end
                expect(zp).to receive(:bitstreams) { bitstreams }
              end

              downloaded = @sync_task.harvest_records
              downloaded_array = downloaded.to_a
              expect(downloaded_array.size).to eq(resource_contents.size)
              downloaded_array.each_with_index do |rc, i|
                expect(rc.content).to eq(resource_contents[i])
              end
            end

            it 'returns an Enumerator::Lazy' do
              expect(@sync_task.harvest_records).to be_a(Enumerator::Lazy)
            end
          end
        end
      end
    end
  end
end
