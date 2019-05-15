# frozen_string_literal: true

require 'stash/organization/ror'

module StashDatacite
  class Affiliation < ActiveRecord::Base

    include Stash::Organization::Ror

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
      ror_org = find_by_ror_id(ror_id)
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

    # We want to try to always use the ROR long_name when possible so check the incoming
    # long name as well as the ROR-ized version of the long_name to find our record
    def self.from_long_name(long_name)
      return nil if long_name.blank?
      affil = find_or_initialize_by_long_name(long_name)
      # If the record already has a ROR id, no need to do a lookup
      return affil if affil.ror_id.present?
      ror_org = find_by_ror_long_name(long_name)
      # The record didn't exist in ROR so just return as is
      return affil if ror_org.blank?
      # Otherwise use the ROR id and long_name
      affil.ror_id = ror_org[:id]
      affil.long_name = ror_org[:name]
      affil
    end

    def self.find_or_initialize_by_long_name(long_name)
      affil = Affiliation.where('LOWER(long_name) = LOWER(?)', long_name)
      (affil.any? ? affil.first : Affiliation.new(long_name: long_name))
    end

    def self.find_by_ror_long_name(long_name)
      # Do a ROR lookup for the long_name
      find_first_by_ror_name(long_name)
    end

    private

    def strip_whitespace
      self.long_name = long_name.strip unless long_name.nil?
    end

  end
end
