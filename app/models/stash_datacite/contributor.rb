# frozen_string_literal: true

# == Schema Information
#
# Table name: dcs_contributors
#
#  id                 :integer          not null, primary key
#  award_description  :string(191)
#  award_number       :text(65535)
#  award_title        :string(191)
#  award_uri          :string(191)
#  contributor_name   :text(65535)
#  contributor_type   :string           default("funder")
#  funder_order       :integer
#  identifier_type    :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  name_identifier_id :string(191)
#  resource_id        :integer
#
# Indexes
#
#  index_dcs_contributors_on_contributor_type    (contributor_type)
#  index_dcs_contributors_on_funder_order        (funder_order)
#  index_dcs_contributors_on_identifier_type     (identifier_type)
#  index_dcs_contributors_on_name_identifier_id  (name_identifier_id)
#  index_dcs_contributors_on_resource_id         (resource_id)
#
module StashDatacite
  class Contributor < ApplicationRecord
    self.table_name = 'dcs_contributors'
    has_paper_trail

    belongs_to :resource, class_name: StashEngine::Resource.to_s
    belongs_to :name_identifier, optional: true
    has_and_belongs_to_many :affiliations, class_name: 'StashDatacite::Affiliation'

    scope :completed, -> {
                        where("TRIM(IFNULL(contributor_name, '')) > '' AND TRIM('N/A' FROM IFNULL(contributor_name, '')) > ''")
                      } # only non-null & blank, no N/A funders
    # scope :completed, ->  { where("TRIM(IFNULL(award_number, '')) > '' AND TRIM(IFNULL(contributor_name, '')) > ''") } # only non-null & blank

    scope :funder, -> { where(contributor_type: 'funder').order(funder_order: :asc, id: :asc) }
    scope :sponsors, -> { where(contributor_type: 'sponsor') }
    scope :rors, -> { where(identifier_type: 'ror') }

    ContributorTypes = Datacite::Mapping::ContributorType.map(&:value)

    ContributorTypesEnum = ContributorTypes.to_h { |i| [i.downcase.to_sym, i.downcase] }
    ContributorTypesStrToFull = ContributorTypes.to_h { |i| [i.downcase, i] }

    # rubocop:disable Style/MapToHash
    # maps DB value to the DataciteMapping class of fun from that gem
    IdentifierTypesToMapping = Datacite::Mapping::FunderIdentifierType.map { |i| [i.value.downcase.gsub(' ', '_'), i] }.to_h

    # maps from enum to the special full name/abbreviation like Crossref Funder ID or ROR
    IdentifierTypesStrToFull = Datacite::Mapping::FunderIdentifierType.map { |i| [i.value.downcase.gsub(' ', '_'), i.value] }.to_h
    # rubocop:enable Style/MapToHash

    enum :contributor_type, ContributorTypesEnum

    before_save :strip_whitespace

    amoeba do
      enable
    end

    # scopes for contributor
    scope :with_award_numbers, -> { where("award_number <> ''") }

    def contributor_type_friendly=(type)
      self.contributor_type = type.to_s.downcase unless type.blank?
    end

    def contributor_type_friendly
      return nil if contributor_type.blank?

      ContributorTypesStrToFull[contributor_type]
    end

    def self.contributor_type_mapping_obj(str)
      return nil if str.nil?

      Datacite::Mapping::ContributorType.find_by_value(str)
    end

    def contributor_type_mapping_obj
      return nil if contributor_type_friendly.nil?

      Contributor.contributor_type_mapping_obj(contributor_type_friendly)
    end

    def contributor_name_friendly
      if contributor_name&.end_with?('*')
        contributor_name[0..-2]
      else
        contributor_name
      end
    end

    # gives the mapping object used to submit through Datacite mapping gem
    def identifier_type_mapping_obj
      return nil if identifier_type.blank?

      IdentifierTypesToMapping[identifier_type]
    end

    # gives a printable name
    def identifier_type_friendly
      return nil if identifier_type.blank?

      IdentifierTypesStrToFull[identifier_type]
    end

    # this is to simulate the bad old structure where a user can only have one affiliation
    def affiliation_id=(affil_id)
      self.affiliation_ids = affil_id
    end

    # this is to simulate the bad old structure where a user can only have one affiliation
    def affiliation_id
      affiliation_ids.try(:first)
    end

    # this is to simulate the bad old structure where a user can only have one affiliation
    def affiliation=(affil)
      affiliations.clear
      affiliations << affil
    end

    # this is to simulate the bad old structure where a user can only have one affiliation
    def affiliation
      affiliations.try(:first)
    end

    def payment_exempted?
      return false if contributor_name.blank? || contributor_type != 'funder'
      return true if StashEngine::Funder.exemptions.find_by(name: contributor_name)

      false
    end

    def payer_funder
      return nil if contributor_name.blank? || contributor_type != 'funder'

      StashEngine::Funder.exemptions.find_by(name: contributor_name)
    end

    private

    def strip_whitespace
      self.contributor_name = contributor_name.strip unless contributor_name.nil?
      self.award_number = award_number.strip unless award_number.nil?
    end
  end
end
