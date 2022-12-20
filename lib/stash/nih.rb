require 'http'

# Library for working with the API for the National Institutes of Health

module Stash
  class NIH

    NIH_BASE = 'https://api.reporter.nih.gov/v1/projects/Search'.freeze
    NIH_ID = 'http://dx.doi.org/10.13039/100000002'.freeze

    # Mapping from nonstandard names/spellings that appear in actual NIH grants to the standardized spelling
    # rubocop:disable Layout/LineLength
    IC_MAPPING =
      {
        'National Heart Lung and Blood Institute' => 'National Heart, Lung, and Blood Institute',
        'National Institute of Arthritits and Musculoskeletal and Skin Diseases' => 'National Institute of Arthritis and Musculoskeletal and Skin Diseases',
        'National Library of Medicine' => 'U.S. National Library of Medicine',
        'John E. Fogarty International Center for Advanced Study in the Health Sciences' => 'Fogarty International Center',
        'National Center for Complementary and Intergrative Health' => 'National Center for Complementary and Integrative Health'
      }.freeze
    # rubocop:enable Layout/LineLength

    def self.find_grant(award_id)
      return if award_id.blank? || award_id.size < 5

      response = HTTP.post(NIH_BASE, json: nih_award_id_criteria(award_id))
      resp = JSON.parse(response)
      return unless resp.present?
      grants = resp['results']
      return if grants.blank?

      grants[0]
    end

    # Update a StashDatacite::Contributor using the named NIH Institute or Center
    def self.set_contributor_to_ic(contributor:, ic_name:)
      group_record = StashDatacite::ContributorGrouping.where(name_identifier_id: NIH_ID).first
      return if group_record.blank?

      ics = group_record.json_contains
      ics.each do |ic|
        next unless ic['contributor_name'] == clean_ic_name(ic_name)

        contributor.update(contributor_name: ic['contributor_name'],
                           identifier_type: ic['identifier_type'],
                           name_identifier_id: ic['name_identifier_id'])
        break
      end
    end

    def self.clean_ic_name(ic_name)
      IC_MAPPING[ic_name] || ic_name
    end

    # Criteria object that is passed as a query to the NIH API, initilaized with a single award_id
    def self.nih_award_id_criteria(award_id)
      {
        criteria:
         {
           project_nums: [award_id]
         },
        include_fields: %w[
          ProjectTitle AbstractText FiscalYear
          Organization OrgCountry OrgState OrgName
          ProjectNum ProjectNumSplit
          ContactPiName PrincipalInvestigators ProgramOfficers
          ProjectStartDate ProjectEndDate
          AwardAmount AgencyIcFundings PrefTerms
        ],
        offset: 0,
        limit: 25
      }
    end

  end
end
