# == Schema Information
#
# Table name: stash_engine_ror_orgs
#
#  id         :bigint           not null, primary key
#  ror_id     :string(191)
#  name       :string(191)
#  home_page  :string(191)
#  country    :string(191)
#  acronyms   :json
#  aliases    :json
#  isni_ids   :json
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
module StashEngine
  class RorOrg < ApplicationRecord
    self.table_name = 'stash_engine_ror_orgs'
    validates :ror_id, uniqueness: { case_sensitive: true }
    include Stash::Indexer::RorIndexer

    ROR_MAX_RESULTS = 30

    # Search the RorOrgs for the given string. This will search name, acronyms, aliases, etc.
    # @return an Array of Hashes { id: 'https://ror.org/12345', name: 'Sample University' }
    def self.find_by_ror_name(query)
      return [] unless query.present?

      if query.start_with?('https://')
        resp = where('LOWER(ror_id) LIKE LOWER(?)', "#{query}%").limit(ROR_MAX_RESULTS)
        return map_resp(resp).flatten.uniq
      end

      query = query.downcase
      # First, find matches at the beginning of the name string, and exact matches in the acronyms/aliases
      resp = where("LOWER(name) LIKE ? OR JSON_SEARCH(LOWER(acronyms), 'all', ?) or JSON_SEARCH(LOWER(aliases), 'all', ?)",
                   "#{query}%", query.to_s, query.to_s).limit(ROR_MAX_RESULTS)
      results = map_resp(resp)

      # If we don't have enough results, find matches at the beginning of the acronyms/aliases
      if results.size < ROR_MAX_RESULTS
        resp = where("JSON_SEARCH(LOWER(acronyms), 'all', ?) or JSON_SEARCH(LOWER(aliases), 'all', ?)",
                     "#{query}%", "#{query}%").limit(ROR_MAX_RESULTS - results.size)
        results.concat(map_resp(resp))
      end

      # If we don't have enough results, find matches elsewhere in the name string
      if results.size < ROR_MAX_RESULTS
        resp = where('LOWER(name) LIKE ?', "%#{query}%").limit(ROR_MAX_RESULTS - results.size)
        results.concat(map_resp(resp))
      end

      results.flatten.uniq
    end

    def self.map_resp(resp)
      resp.map { |r| { id: r.ror_id, name: r.name, country: r.country, acronyms: r.acronyms, aliases: r.aliases } }
    end

    # Search the RorOrgs for the given string. This will search name, acronyms, aliases, etc.
    # @return an Array of Hashes { id: 'https://ror.org/12345', name: 'Sample University' }
    # This method is used for auto-matching scripts, where no human has to confirm the match.
    def self.find_by_name_for_auto_matching_db(query)
      max_results = 10
      return [] unless query.present?

      query = query.downcase
      # First, find matches at the beginning of the name string, and exact matches in the acronyms/aliases
      resp = where("LOWER(name) LIKE ? OR JSON_SEARCH(LOWER(acronyms), 'all', ?) or JSON_SEARCH(LOWER(aliases), 'all', ?)",
                   "#{query}%", query.to_s, query.to_s).limit(max_results)
      results = resp.map do |r|
        { id: r.ror_id, name: r.name, country: r.country, acronyms: r.acronyms, aliases: r.aliases }
      end

      return results if results.any?

      # If we don't have enough results, find matches at the beginning of the acronyms/aliases
      resp = where("JSON_SEARCH(LOWER(acronyms), 'all', ?) or JSON_SEARCH(LOWER(aliases), 'all', ?)",
                   "#{query}%", "#{query}%").limit(max_results)
      resp.map do |r|
        { id: r.ror_id, name: r.name, country: r.country, acronyms: r.acronyms, aliases: r.aliases }
      end
    end

    def self.find_by_name_for_auto_matching(query)
      max_results = 10
      return [] unless query.present?

      query = query.downcase
      # First, find matches at the beginning of the name string, and exact matches in the acronyms/aliases
      pp search('', fq: ["name:#{query}*", "aliases:#{query}", "acronyms:#{query}"], limit: max_results)
      # resp = where("LOWER(name) LIKE ? OR JSON_SEARCH(LOWER(acronyms), 'all', ?) or JSON_SEARCH(LOWER(aliases), 'all', ?)",
      #   "#{query}%", query.to_s, query.to_s).limit(max_results)
      # results = resp.map do |r|
      #   { id: r.ror_id, name: r.name, country: r.country, acronyms: r.acronyms, aliases: r.aliases }
      # end

      return results if results.any?

      # If we don't have enough results, find matches at the beginning of the acronyms/aliases
      resp = where("JSON_SEARCH(LOWER(acronyms), 'all', ?) or JSON_SEARCH(LOWER(aliases), 'all', ?)",
                   "#{query}%", "#{query}%").limit(max_results)
      resp.map do |r|
        { id: r.ror_id, name: r.name, country: r.country, acronyms: r.acronyms, aliases: r.aliases }
      end
    end

    # Return the first match for the given name
    # @return a StashEngine::RorOrg or nil
    def self.find_first_by_ror_name(ror_name)
      where(name: ror_name)&.first
    end

    # Return the first match for the given axact name in name, alias, or acronym
    # @return a StashEngine::RorOrg or nil
    def self.find_first_ror_by_phrase(phrase)
      query = phrase.downcase
      where(
        "LOWER(name) = ? OR JSON_SEARCH(LOWER(acronyms), 'all', ?) or JSON_SEARCH(LOWER(aliases), 'all', ?)",
        query.to_s, query.to_s, query.to_s
      )&.first
    end

    # Search for a specific organization.
    # @return a StashEngine::RorOrg or nil
    def self.find_by_ror_id(ror_id)
      where(ror_id: ror_id)&.first
    end

    # Search for a specific organization.
    # @return a StashEngine::RorOrg or nil
    def self.find_by_isni_id(isni_id)
      isni_id = standardize_isni_format(isni_id)
      where("isni_ids LIKE '%#{isni_id}%'")&.first
    end

    class << self
      private

      def standardize_isni_format(isni_id)
        # Remove standardized prefix if it exists
        isni_id.match(%r{http://www.isni.org/isni/(.*)/}) do |m|
          isni_id = m[1]
        end
        isni_id.match(/ISNI?:(.*)/) do |m|
          isni_id = m[1]
        end
        # If it has the digits with embedded spaces, keep it
        return isni_id if isni_id =~ /\d{4} \d{4} \d{4} \d{3,4}X?/

        # If it has no spaces, add them
        isni_id.match(/(\d{4})(\d{4})(\d{4})(\d{3,4}X?)/) do |m|
          return "#{m[1]} #{m[2]} #{m[3]} #{m[4]}"
        end
        # Otherwise, throw an error
        raise "Unexpected structure of ISNI: #{isni_id}; use either 16 digits or 4 sets of 4 digits with spaces between."
      end

    end
  end
end
