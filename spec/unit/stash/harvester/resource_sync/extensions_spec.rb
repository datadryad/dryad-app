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

      it 'is lazy'
    end
  end

  describe ChangeList do
    describe '#each_resource' do
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
        list.each_resource(in_range: Time.utc(0)..Time.new) do |r|
          r.get
        end
      end

      it 'filters out resources outside the range' do
        resources = Array.new(3) { Resource.new(uri: 'http://example.org/') }
        resources[0].modified_time = Time.utc(1999, 1, 1)
        expect(resources[0]).not_to receive(:get)
        resources[1].modified_time = Time.utc(2001, 1, 1)
        expect(resources[1]).to receive(:get)
        resources[2].modified_time = Time.utc(2002, 1, 1)
        expect(resources[2]).to receive(:get)

        range = Time.utc(2000, 1, 1)..Time.utc(2003, 1, 1)
        list = ChangeList.new(resources: resources)
        list.each_resource(in_range: range) do |r|
          r.get
        end
      end

      it 'is lazy'
    end
  end
end
