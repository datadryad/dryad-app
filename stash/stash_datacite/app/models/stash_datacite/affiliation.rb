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
    # from our DB. If if one isn't present, just create a new affiliation with an
    # asterisk on the name, so we know it is not associated with ROR.
    def self.from_long_name(long_name)
      return nil if long_name.blank?
      
      affil = find_or_initialize_by_long_name(long_name)
      return affil if affil.ror_id.present?

      # The record didn't exist in ROR so return it with the asterisk
      affil.long_name = affil.long_name + "*"
      affil
    end

    def self.find_or_initialize_by_long_name(long_name)
      affil = Affiliation.where('LOWER(long_name) = LOWER(?)', long_name)
      (affil.any? ? affil.first : Affiliation.new(long_name: long_name))
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
