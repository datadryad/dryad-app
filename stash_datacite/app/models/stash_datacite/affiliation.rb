# frozen_string_literal: true

require 'stash/organization/ror'

module StashDatacite
  class Affiliation < ActiveRecord::Base

    include Stash::Organization::Ror

    self.table_name = 'dcs_affiliations'
    has_and_belongs_to_many :authors, class_name: 'StashEngine::Author', join_table: 'dcs_affiliations_authors'
    has_and_belongs_to_many :contributors, class_name: 'StashDatacite::Contributor'

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

    def self.reconcile_affiliation(ror_id, long_name)
      return nil if long_name.blank?
      # If the Affiliation is already in the DB then get its id and update the ROR id if appropriate
      affil = Affiliation.where('LOWER(long_name) = LOWER(?)', long_name).first
      if affil.present?
        affil.update(ror_id: ror_id) if affil.ror_id.blank? && ror_id.present?
      else
        affil = Affiliation.create(ror_id: ror_id, long_name: long_name)
      end
      affil
    end

    private

    def strip_whitespace
      self.long_name = long_name.strip unless long_name.nil?
    end

  end
end
