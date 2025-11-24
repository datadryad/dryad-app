module Integrations
  class NSF < Integrations::Base
    BASE_URL       = 'https://www.research.gov/awardapi-service/v1/'.freeze
    DEFAULT_FIELDS = %w[agency fundProgramName id offset primaryProgram title date orgLongName orgLongName2].freeze

    def search_awards(award_ids, fields = DEFAULT_FIELDS)
      uri    = "#{BASE_URL}awards.json"
      params = {
        printFields: fields.join(','),
        id: award_ids.join(',')
      }

      results = get_json(uri, params)
      begin
        results['response']['award']
      rescue StandardError
        []
      end
    end
  end
end
