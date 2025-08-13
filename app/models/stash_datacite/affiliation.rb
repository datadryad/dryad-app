# frozen_string_literal: true

# == Schema Information
#
# Table name: dcs_affiliations
#
#  id           :integer          not null, primary key
#  abbreviation :text(65535)
#  long_name    :text(65535)
#  short_name   :text(65535)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  ror_id       :string(191)
#
# Indexes
#
#  index_dcs_affiliations_on_long_name   (long_name)
#  index_dcs_affiliations_on_ror_id      (ror_id)
#  index_dcs_affiliations_on_short_name  (short_name)
#
module StashDatacite
  class Affiliation < ApplicationRecord
    self.table_name = 'dcs_affiliations'

    has_and_belongs_to_many :contributors, class_name: 'StashDatacite::Contributor'
    has_many :affiliation_authors, class_name: 'StashDatacite::AffiliationAuthor', dependent: :destroy
    has_many :authors, class_name: 'StashEngine::Author', through: :affiliation_authors

    belongs_to :ror_org, class_name: 'StashEngine::RorOrg', primary_key: 'ror_id', foreign_key: 'ror_id', optional: true

    validates :long_name, presence: true

    before_save :strip_whitespace

    # prefer short_name if it is set over long name and make string
    def smart_name
      return '' if short_name.blank? && long_name.blank?

      chosen_name = (short_name.blank? ? long_name.strip : short_name.strip)
      if chosen_name&.end_with?('*')
        chosen_name[0..-2]
      else
        chosen_name
      end
    end

    def country_name
      return nil if ror_org.nil? || ror_org.country.nil?

      ror_org.country
    end

    # Get an affiliation by long_name.
    # Our first preference is to reuse an existing affiliation from our DB.
    # Otherwise, if check_ror is true, search for a name match in ROR.
    # As a last resort, create a new affiliation without a ror ID.
    def self.from_long_name(long_name:, check_ror: false)
      return nil if long_name.blank?

      db_affils = Affiliation.where('LOWER(long_name) = LOWER(?)', long_name) +
                  Affiliation.where('LOWER(long_name) = LOWER(?)', "#{long_name}*")
      return db_affils.first if db_affils.any?

      if check_ror
        ror_affil = find_by_ror_long_name(long_name: long_name)
        return ror_affil if ror_affil.present?
      end

      Affiliation.new(long_name: long_name)
    end

    # Get an affiliation by ror_id. We prefer to reuse an existing affiliation
    # from our DB. If one isn't present, just create a new affiliation.
    def self.from_ror_id(ror_id:)
      return nil if ror_id.blank?

      db_affils = Affiliation.where('LOWER(ror_id) = LOWER(?)', ror_id)
      return db_affils.first if db_affils.any?

      ror_org = StashEngine::RorOrg.find_by_ror_id(ror_id)
      Affiliation.new(long_name: ror_org&.name, ror_id: ror_id) if ror_org.present?
    end

    def self.from_isni_id(isni_id:)
      return nil if isni_id.blank?

      ror_org = StashEngine::RorOrg.find_by_isni_id(isni_id)
      from_ror_id(ror_id: ror_org.ror_id) if ror_org.present?
    end

    def self.find_by_ror_long_name(long_name:)
      # Do a lookup for the long_name
      ror_org = StashEngine::RorOrg.find_first_by_ror_name(long_name)
      ror_org = StashEngine::RorOrg.find_first_ror_by_phrase(long_name) unless ror_org.present?
      Affiliation.new(long_name: ror_org.name, ror_id: ror_org.id) if ror_org.present?
    end

    def as_api_json
      {
        name: smart_name,
        ror_id: ror_id
      }
    end

    private

    def strip_whitespace
      self.long_name = long_name.strip unless long_name.nil?
    end

  end
end
