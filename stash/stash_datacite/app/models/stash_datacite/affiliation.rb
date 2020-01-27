# frozen_string_literal: true

require 'stash/organization/ror'

module StashDatacite
  class Affiliation < ActiveRecord::Base

    include Stash::Organization

    self.table_name = 'dcs_affiliations'
    has_and_belongs_to_many :authors, class_name: 'StashEngine::Author', join_table: 'dcs_affiliations_authors'
    has_and_belongs_to_many :contributors, class_name: 'StashDatacite::Contributor'

    validates :long_name, presence: true, uniqueness: true

    before_save :strip_whitespace

    # prefer short_name if it is set over long name and make string
    def smart_name
      return '' if short_name.blank? && long_name.blank?
      (short_name.blank? ? long_name.strip : short_name.strip)
    end

    def country_name
      return nil if ror_id.blank?
      ror_org = Stash::Organization::Ror.find_by_ror_id(ror_id)
      return nil if ror_org.nil? || ror_org.country.nil?
      ror_org.country['country_name']
    end

    def fee_waivered?
      return false if country_name.nil?
      return false unless country_name.present?
      fee_waiver_countries&.include?(country_name)
    end

    def fee_waiver_countries
      APP_CONFIG.fee_waiver_countries || []
    end

    # Get an affiliation by long_name. We prefer to reuse an existing affiliation
    # from our DB. If one isn't present, just create a new affiliation with an
    # asterisk on the name, so we know it has not been validated with ROR.
    def self.from_long_name(long_name)
      return nil if long_name.blank?

      db_affils = Affiliation.where('LOWER(long_name) = LOWER(?)', long_name) +
                  Affiliation.where('LOWER(long_name) = LOWER(?)', long_name + '*')
      return db_affils.first if db_affils.any?

      Affiliation.new(long_name: long_name + '*')
    end

    # Get an affiliation by ror_id. We prefer to reuse an existing affiliation
    # from our DB. If one isn't present, just create a new affiliation.
    def self.from_ror_id(ror_id)
      return nil if ror_id.blank?

      db_affils = Affiliation.where('LOWER(ror_id) = LOWER(?)', ror_id)
      return db_affils.first if db_affils.any?

      ror_org = Stash::Organization::Ror.find_by_ror_id(ror_id)
      Affiliation.new(long_name: ror_org.name, ror_id: ror_id)
    rescue Stash::Organization::RorError
      nil
    end

    def self.find_by_ror_long_name(long_name)
      # Do a Stash::Organization::Ror lookup for the long_name
      Stash::Organization::Ror.find_first_by_ror_name(long_name)
    rescue Stash::Organization::RorError
      []
    end

    private

    def strip_whitespace
      self.long_name = long_name.strip unless long_name.nil?
    end

  end
end
