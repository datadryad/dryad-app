require 'faker'
require 'json'
module Fixtures
  module StashApi
    class Metadata

      def initialize
        @metadata = ActiveSupport::HashWithIndifferentAccess.new
      end

      def hash
        @metadata.with_indifferent_access
      end

      def json
        @metadata.to_json
      end

      def make_minimal
        add_title
        add_abstract
        add_author
        add_research_domain
        add_funder
      end

      def make_minimal_ordered_authors
        add_title
        add_abstract
        @metadata[:authors] = [] # reset to 0 authors
        add_author(order: 2)
        add_author(order: 1)
        add_author(order: 0)
        add_research_domain
      end

      def add_field(field_name:, value: nil)
        @metadata[field_name.to_sym] = value
      end

      def add_title
        @metadata.merge!(title: Faker::Book.title)
      end

      def add_author(order: nil)
        create_key_and_array(key: :authors)
        @metadata[:authors].push(
          { firstName: Faker::Name.first_name,
            lastName: Faker::Name.last_name,
            email: Faker::Internet.email,
            orcid: "#{Faker::Number.number(digits: 4)}-#{Faker::Number.number(digits: 4)}-" \
                   "#{Faker::Number.number(digits: 4)}-#{Faker::Number.number(digits: 4)}",
            affiliation: Faker::University.name,
            order: order }.with_indifferent_access
        )
      end

      def add_research_domain
        fos = Faker::Science.science(:natural)
        StashDatacite::Subject.create(subject: fos, subject_scheme: 'fos') # the fos field must exist in the database to be recognized
        @metadata.merge!(fieldOfScience: fos)
      end

      def add_related_work(work_type: 'article')
        create_key_and_array(key: :relatedWorks)
        @metadata[:relatedWorks].push(
          {
            relationship: work_type,
            identifierType: 'DOI',
            identifier: "10.#{Faker::Number.number(digits: 4)}/fakedoi.#{Faker::Number.number(digits: 4)}-#{Faker::Number.number(digits: 4)}"
          }.with_indifferent_access
        )
      end

      def add_abstract
        @metadata.merge!(abstract: Faker::Lorem.paragraph)
      end

      def add_place
        create_key_and_array(key: :locations)
        @metadata[:locations].push(
          place: random_placename
        )
      end

      def add_point
        create_key_and_array(key: :locations)
        @metadata[:locations].push(
          point: random_point
        )
      end

      def add_box
        create_key_and_array(key: :locations)
        @metadata[:locations].push(
          box: random_box
        )
      end

      def add_associated_place_and_point
        create_key_and_array(key: :locations)
        @metadata[:locations].push(
          place: random_placename,
          point: random_point
        )
      end

      def add_associated_place_and_box
        create_key_and_array(key: :locations)
        @metadata[:locations].push(
          place: random_placename,
          box: random_box
        )
      end

      def add_associated_place_point_and_box
        create_key_and_array(key: :locations)
        @metadata[:locations].push(
          place: random_placename,
          point: random_point,
          box: random_box
        )
      end

      def add_associated_point_and_box
        create_key_and_array(key: :locations)
        @metadata[:locations].push(
          point: random_point,
          box: random_box
        )
      end

      def create_key_and_array(key:)
        @metadata[key] = [] unless @metadata[key]
      end

      def random_placename
        case rand(3)
        when 0
          Faker::Address.city
        when 1
          Faker::Address.state
        else
          Faker::Address.country
        end
      end

      def random_point
        { latitude: Faker::Address.latitude,
          longitude: Faker::Address.longitude }
      end

      def random_box
        {
          swLongitude: Faker::Address.longitude,
          swLatitude: Faker::Address.latitude,
          neLongitude: Faker::Address.longitude,
          neLatitude: Faker::Address.latitude
        }
      end

      def add_funder
        create_key_and_array(key: :funders)
        @metadata[:funders].push(
          {
            organization: Faker::Company.name,
            awardNumber: Faker::Number.number(digits: 4),
            identifier: "http://dx.doi.org/10.13039/fakedoi.#{Faker::Number.number(digits: 4)}-#{Faker::Number.number(digits: 4)}",
            identifierType: 'crossref_funder_id'
          }
        )
      end

      def add_keywords(number: 3)
        @metadata[:keywords] = Faker::Lorem.words(number: number)
      end

    end
  end
end
