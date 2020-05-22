# frozen_string_literal: true

require 'stash/organization/ror'

module StashDatacite
  class Affiliation < ActiveRecord::Base

    include Stash::Organization

    self.table_name = 'dcs_affiliations'
    has_and_belongs_to_many :authors, class_name: 'StashEngine::Author', join_table: 'dcs_affiliations_authors'
    has_and_belongs_to_many :contributors, class_name: 'StashDatacite::Contributor'

    validates :long_name, presence: true

    before_save :strip_whitespace

    # prefer short_name if it is set over long name and make string
    def smart_name(show_asterisk: false)
      return '' if short_name.blank? && long_name.blank?
      chosen_name = (short_name.blank? ? long_name.strip : short_name.strip)
      if chosen_name.end_with?('*') && !show_asterisk
        chosen_name[0..-2]
      else
        chosen_name
      end
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

    # Get an affiliation by long_name.
    # Our first preference is to reuse an existing affiliation from our DB.
    # Otherwise, if check_ror is true, search for a name match in ROR.
    # As a last resort, create a new affiliation with an asterisk on the name, so we know it has not been validated.
    def self.from_long_name(long_name:, check_ror: false)
      return nil if long_name.blank?

      db_affils = Affiliation.where('LOWER(long_name) = LOWER(?)', long_name) +
                  Affiliation.where('LOWER(long_name) = LOWER(?)', "#{long_name}*")
      return db_affils.first if db_affils.any?

      if check_ror
        ror_affil = find_by_ror_long_name(long_name: long_name)
        return ror_affil if ror_affil.present?
      end

      Affiliation.new(long_name: "#{long_name}*")
    end

    # Get an affiliation by ror_id. We prefer to reuse an existing affiliation
    # from our DB. If one isn't present, just create a new affiliation.
    def self.from_ror_id(ror_id:)
      return nil if ror_id.blank?
      db_affils = Affiliation.where('LOWER(ror_id) = LOWER(?)', ror_id)
      return db_affils.first if db_affils.any?
      ror_org = Stash::Organization::Ror.find_by_ror_id(ror_id)
      Affiliation.new(long_name: ror_org&.name, ror_id: ror_id)
    rescue Stash::Organization::RorError
      nil
    end

    def self.from_isni_id(isni_id:)
      puts "called affiliation.from_isni_id with |#{isni_id}|"
      return nil if isni_id.blank?
      ror_org = Stash::Organization::Ror.find_by_isni_id(isni_id)
      return nil if ror_org.blank?
      from_ror_id(ror_id: ror_org.id)
    end

    def self.find_by_ror_long_name(long_name:)
      # Do a Stash::Organization::Ror lookup for the long_name
      ror_org = Stash::Organization::Ror.find_first_by_ror_name(long_name)
      Affiliation.new(long_name: ror_org.name, ror_id: ror_org.id) if ror_org.present?
    rescue Stash::Organization::RorError
      []
    end

    private

    def strip_whitespace
      self.long_name = long_name.strip unless long_name.nil?
    end

  end
end
