module Contributors
  class UpdateByAwardService
    attr_reader :contributor

    def initialize(contributor)
      @contributor = contributor
    end

    def call
      return response_row('No award number') if contributor.award_number.blank?

      # search on NSF API
      searchable_award_number = nsf_award_number || contributor.award_number
      if searchable_award_number
        nsf_info = AwardMetadataService.new(
          contributor,
          api_integration_key: 'NSF',
          api_integration: Integrations::NSF,
          award_number: searchable_award_number
        ).award_details
        if nsf_info && nsf_info[:award_number] == searchable_award_number.to_s
          initial_number = contributor.award_number
          Contributors::FixAwardService.new(contributor, nsf_info).call
          return response_row('Update', initial_number)
        end
      end

      # search on NIH API
      nih_info = AwardMetadataService.new(contributor, api_integration_key: 'NIH', api_integration: Integrations::NIH).award_details
      if nih_info && nih_award_number_matcher(nih_info)
        initial_number = contributor.award_number
        Contributors::FixAwardService.new(contributor, nih_info).call
        return response_row('Update', initial_number)
      end

      response_row('Not Found')
    end

    private

    def nsf_award_number
      num = contributor.award_number
        .strip
        .gsub(/[\u2010\u2011\u2012\u2013\u2014\u2015\u2212]/, '-')
        .match(/\A(?:NSF[\s_-])?([a-z]{3,4}:?)?\s*[:\-–—‐]?\s*(\d+)\z/i)
      return unless num

      num[2]
    end

    def nih_award_number_matcher(nih_info)
      # matches
      # (?:[125])? - optional leading 1, 2, or 5
      # #{Regexp.escape(contributor.award_number)} - matches searches award_number exactly
      # (?:-\d{2})? - optionally matches a dash followed by exactly 2 digits (-02)
      # \A … \z → anchors the match to the entire string
      regex = /\A(?:[125])?#{Regexp.escape(contributor.award_number)}(?:-\d{2})?\z/i

      nih_info[:award_number] == contributor.award_number ||
        nih_info[:award_number].start_with?("#{contributor.award_number}-") ||
        nih_info[:award_number].to_s.match?(regex)
    end

    def response_row(status, initial_award_number = nil)
      {
        status: status,
        contributor_id: contributor.id,
        identifier: contributor.resource.identifier.to_s,
        identifier_id: contributor.resource.identifier_id,
        resource_id: contributor.resource.id,
        award_number: contributor.award_number,
        initial_award_number: initial_award_number
      }
    end
  end
end
