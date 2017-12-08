module StashApi
  class Version
    class Metadata

      def initialize(resource:)
        @resource = resource
      end

      def value
        {
            title: @resource.title,
            authors: Authors.new(resource: @resource).value,
            abstract: Abstract.new(resource: @resource).value,
            funders: Funders.new(resource: @resource).value,
            keywords: Keywords.new(resource: @resource).value,
            methods: Methods.new(resource: @resource).value,
            usageNotes: UsageNotes.new(resource: @resource).value,
            locations: Locations.new(resource: @resource).value,
            relatedWorks: ''
        }
      end
    end
  end
end