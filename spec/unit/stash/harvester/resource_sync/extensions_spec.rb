require 'spec_helper'

module Resync

  describe ResourceList do
    describe '#each_resource' do
      it 'invokes the specified block on each resource in the list' do
        resources = Array.new(3) do |index|
          uri = URI("http://example.org/resource-#{index}")
          resource = Resource.new(uri: uri)
          expect(resource).to receive(:get)
          resource
        end

        list = ResourceList.new(resources: resources)
        list.each_resource do |r|
          r.get
        end
      end

      it 'is lazy' do
        resources = Array.new(3) do |index|
          uri = URI("http://example.org/resource-#{index}")
          resource = Resource.new(uri: uri)
          resource
        end

        expect(resources[0]).to receive(:get)
        expect(resources[1]).not_to receive(:get)
        expect(resources[2]).not_to receive(:get)

        list = ResourceList.new(resources: resources)
        list.each_resource do |r|
          r.get
          break
        end
      end
    end
  end

  describe ChangeList do
    describe '#each_change' do
      it 'invokes the specified block on each resource in the list' do
        time = Time.new
        resources = Array.new(3) do |index|
          mtime = Time.utc(time.year - index, time.month, time.day)
          uri = URI("http://example.org/resource-#{index}")
          resource = Resource.new(modified_time: mtime, uri: uri)
          expect(resource).to receive(:get)
          resource
        end

        list = ChangeList.new(resources: resources)
        list.each_change(in_range: Time.utc(0)..Time.new) do |r|
          r.get
        end
      end

      it 'filters out resources outside the range' do
        resources = Array.new(3) { Resource.new(uri: 'http://example.org/') }
        resources[0].modified_time = Time.utc(1999, 1, 1)
        resources[1].modified_time = Time.utc(2001, 1, 1)
        resources[2].modified_time = Time.utc(2002, 1, 1)

        expect(resources[0]).not_to receive(:get)
        expect(resources[1]).to receive(:get)
        expect(resources[2]).to receive(:get)

        range = Time.utc(2000, 1, 1)..Time.utc(2003, 1, 1)
        list = ChangeList.new(resources: resources)
        list.each_change(in_range: range) do |r|
          r.get
        end
      end

      it 'is lazy' do
        resources = Array.new(3) { Resource.new(uri: 'http://example.org/') }
        resources[0].modified_time = Time.utc(1999, 1, 1)
        resources[1].modified_time = Time.utc(2001, 1, 1)
        resources[2].modified_time = Time.utc(2002, 1, 1)
        expect(resources[1]).to receive(:get)
        expect(resources[2]).not_to receive(:get)

        range = Time.utc(2000, 1, 1)..Time.utc(2003, 1, 1)
        list = ChangeList.new(resources: resources)
        list.each_change(in_range: range) do |r|
          r.get
          break
        end
      end
    end
  end

  describe ResourceListIndex do
    before(:each) do
      @helper = instance_double(Client::HTTPHelper)
      @client = Client.new(helper: @helper)
    end

    describe '#each_resource' do
      it 'flattens the child resourcelists' do
        resource_index_uri = URI('http://example.com/dataset1/resourcelist.xml')
        resource_index_data = File.read('spec/data/resync/resource-list-index.xml')
        expect(@helper).to receive(:fetch).with(uri: resource_index_uri).and_return(resource_index_data)
        
        list1_uri = URI('http://example.com/resourcelist1.xml')
        list1_data = File.read('spec/data/resync/resource-list-1.xml')
        expect(@helper).to receive(:fetch).with(uri: list1_uri).and_return(list1_data)

        list2_uri = URI('http://example.com/resourcelist2.xml')
        list2_data = File.read('spec/data/resync/resource-list-2.xml')
        expect(@helper).to receive(:fetch).with(uri: list2_uri).and_return(list2_data)

        resource_index = @client.get_and_parse(resource_index_uri)
        index = 0
        resource_index.each_resource do |r|
          expect(r.uri).to eq(URI("http://example.com/res#{index + 1}"))
          index += 1
        end
        expect(index).to eq(4)
      end

      it 'is lazy' do
        resource_index_uri = URI('http://example.com/dataset1/resourcelist.xml')
        resource_index_data = File.read('spec/data/resync/resource-list-index.xml')
        expect(@helper).to receive(:fetch).with(uri: resource_index_uri).and_return(resource_index_data)

        list1_uri = URI('http://example.com/resourcelist1.xml')
        list1_data = File.read('spec/data/resync/resource-list-1.xml')
        expect(@helper).to receive(:fetch).with(uri: list1_uri).and_return(list1_data)

        resource_index = @client.get_and_parse(resource_index_uri)
        index = 0
        resource_index.each_resource do |r|
          expect(r.uri).to eq(URI("http://example.com/res#{index + 1}"))
          index += 1
          break if index >= 2
        end
        expect(index).to eq(2)
      end
    end
  end

  describe ChangeListIndex do
    before(:each) do
      @helper = instance_double(Client::HTTPHelper)
      @client = Client.new(helper: @helper)
    end

    describe '#each_change' do
      it 'flattens the child changelists' do
        change_index_uri = URI('http://example.com/dataset1/changelist.xml')
        change_index_data = File.read('spec/data/resync/change-list-index.xml')
        expect(@helper).to receive(:fetch).with(uri: change_index_uri).and_return(change_index_data)

        list1_uri = URI('http://example.com/20130101-changelist.xml')
        list1_data = File.read('spec/data/resync/change-list-1.xml')
        expect(@helper).to receive(:fetch).with(uri: list1_uri).and_return(list1_data)

        list2_uri = URI('http://example.com/20130102-changelist.xml')
        list2_data = File.read('spec/data/resync/change-list-2.xml')
        expect(@helper).to receive(:fetch).with(uri: list2_uri).and_return(list2_data)

        list3_uri = URI('http://example.com/20130103-changelist.xml')
        list3_data = File.read('spec/data/resync/change-list-3.xml')
        expect(@helper).to receive(:fetch).with(uri: list3_uri).and_return(list3_data)

        expected_mtimes = [
          Time.utc(2013, 1, 1, 1),
          Time.utc(2013, 1, 1, 23),
          Time.utc(2013, 1, 2, 1),
          Time.utc(2013, 1, 2, 23),
          Time.utc(2013, 1, 3, 1)
        ]

        change_index = @client.get_and_parse(change_index_uri)
        index = 0
        change_index.each_change(in_range: (Time.utc(0)..Time.new)) do |c|
          res = index % 2 == 0 ? 1 : 2
          expect(c.uri).to eq(URI("http://example.com/res#{res}"))
          expect(c.modified_time).to be_time(expected_mtimes[index])
          index += 1
        end
        expect(index).to eq(5)
      end

      it 'doesn\'t download unnecessary changelists' do
        change_index_uri = URI('http://example.com/dataset1/changelist.xml')
        change_index_data = File.read('spec/data/resync/change-list-index.xml')
        expect(@helper).to receive(:fetch).with(uri: change_index_uri).and_return(change_index_data)

        list2_uri = URI('http://example.com/20130102-changelist.xml')
        list2_data = File.read('spec/data/resync/change-list-2.xml')
        expect(@helper).to receive(:fetch).with(uri: list2_uri).and_return(list2_data)

        list3_uri = URI('http://example.com/20130103-changelist.xml')
        list3_data = File.read('spec/data/resync/change-list-3.xml')
        expect(@helper).to receive(:fetch).with(uri: list3_uri).and_return(list3_data)

        change_index = @client.get_and_parse(change_index_uri)
        count = 0
        change_index.each_change(in_range: (Time.utc(2013, 1, 2, 12)..Time.utc(2013, 1, 3, 0, 30))) do |c|
          expect(c.modified_time).to be_time(Time.utc(2013, 1, 2, 23))
          expect(c.uri).to eq(URI('http://example.com/res2'))
          count +=1
        end
        expect(count).to eq(1)
      end
    end
  end
end
