require 'spec_helper'
require 'ostruct'
require 'byebug'
require 'stash/organization/ror'

module Stash
  module Organization
    describe Ror do

      include Stash::Organization::Ror

      # Not the best test since we're allowing our mocked JSON responses to exceed the 20 item
      # per page limit so it doesn't really get into the paging logic.
      it 'should be able to handle a precise query with only one page of results' do
        @response = generate_ror_response(prefix: 'small', nbr_items: 2)
        resp = MockResponse.new(@response, 200)
        allow_any_instance_of(Stash::Organization::Ror).to receive(:query_ror).and_return(resp)
        expect(find_by_ror_name('University of somewhere').count).to eql(2)
      end

      it 'should be able to handle a broader query with several paged results' do
        @response = generate_ror_response(prefix: 'medium', nbr_items: 25)
        resp = MockResponse.new(@response, 200)
        allow_any_instance_of(Stash::Organization::Ror).to receive(:query_ror).and_return(resp)
        expect(find_by_ror_name('Somewhere').count).to eql(25)
      end

      it 'should limit the number of paged results allowed' do
        max_results = Stash::Organization::Ror::ROR_MAX_RESULTS * Stash::Organization::Ror::MAX_PAGES
        @response = generate_ror_response(prefix: 'large', nbr_items: max_results + 1)
        resp = MockResponse.new(@response, 200)
        allow_any_instance_of(Stash::Organization::Ror).to receive(:query_ror).and_return(resp)
        expect(find_by_ror_name('Somewhere').count).to eql(max_results.to_i)
      end

      def generate_ror_response(prefix:, nbr_items: 1)
        items = []
        max = Stash::Organization::Ror::ROR_MAX_RESULTS * Stash::Organization::Ror::MAX_PAGES

        (nbr_items < max ? nbr_items : max).to_i.times do |i|
          items << {
            'id': "https://ror.org/#{prefix}-#{i}-TEST",
            'name': "University of #{prefix} : #{i}",
            'types': ['Education'],
            'links': ["http://example.org/#{prefix}/#{i}"],
            'aliases': [prefix.to_s],
            'acronyms': [prefix.to_s.upcase],
            'wikipedia_url': "http://example.org/wikipedia/wiki/#{prefix}/#{i}",
            'labels': [{ 'iso639': 'id', 'label': "University of #{prefix} : #{i}" }],
            'country': { 'code': 'US', 'name': 'United States of America' },
            'eternal_ids': { 'GRID': { 'prefered': "grid.#{prefix}.#{i}" } }
          }
        end

        { 'number_of_results': nbr_items, 'time_taken': 3, 'items': items }.to_json
      end

    end

    # Mocks an HttpParty Response object
    class MockResponse

      attr_reader :status_code

      def initialize(payload, status_code)
        @payload = payload
        @status_code = status_code
      end

      def parsed_response
        JSON.parse(@payload)
      end

    end

  end

end
