# frozen_string_literal: true

# basing this structure on that suggested in http://vrybas.github.io/blog/2014/08/15/a-way-to-organize-poros-in-rails/

module StashDatacite
  module Resource
    class Completions

      def initialize(resource)
        @resource = resource
      end

      # A submission is considered duplicate of another resource if it:
      #  - is from the same submitter
      #  - has a different identifier_id (not just a new version)
      #  - has the first four words of the title in common
      def duplicate_submission
        return unless @resource.title && @resource.title.split.size > 3

        other_submissions = StashEngine::Resource.where(user_id: @resource.user_id)
        found_dup = nil
        other_submissions.each do |sub|
          next if sub.identifier_id == @resource.identifier_id
          next unless sub.title

          found_dup = sub if @resource.title.downcase.split[0..3] == sub.title.downcase.split[0..3]
        end
        found_dup
      end

      # Disabling Rubocop's stupid rule.  Yeah, I know what I want and I don't want to know if it's a "related_works?"
      # rubocop:disable Naming/PredicateName
      def has_related_works?
        @resource.related_identifiers.where.not(related_identifier: [nil, '']).count > 0
      end

      def has_related_works_dois?
        return false unless has_related_works?

        return true if @resource.related_identifiers.where(related_identifier_type: 'doi').count > 0

        false
      end
      # rubocop:enable Naming/PredicateName

      def good_related_works_formatting?
        filled_related_dois = @resource.related_identifiers.where(related_identifier_type: 'doi').where.not(related_identifier: [nil, ''])

        filled_related_dois.each do |related_id|
          return false unless related_id.valid_doi_format?
        end

        true
      end

      def good_related_works_validation?
        filled_related_dois = @resource.related_identifiers.where(related_identifier_type: 'doi').where.not(related_identifier: [nil, ''])

        filled_related_dois.each do |related_id|
          next if related_id.verified?

          # may need to live-check for older items that didn't go through validation before
          related_id.update(verified: true) if related_id.valid_doi_format? && related_id.live_url_valid? == true

          return false unless related_id.verified?
        end

        true
      end

    end
  end
end
