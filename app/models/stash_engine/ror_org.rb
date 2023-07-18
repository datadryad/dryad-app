module StashEngine
  class RorOrg < ApplicationRecord
    self.table_name = 'stash_engine_ror_orgs'
    validates :ror_id, uniqueness: { case_sensitive: true }

    ROR_MAX_RESULTS = 20

    # Search the RorOrgs for the given string. This will search name, acronyms, aliases, etc.
    # @return an Array of Hashes { id: 'https://ror.org/12345', name: 'Sample University' }
    def self.find_by_ror_name(query)
      return [] unless query.present?

      query = query.downcase
      results = []

      # First, find matches at the beginning of the name string, or anywhere in the
      # acronyms/aliases
      resp = where('LOWER(name) LIKE ? OR LOWER(acronyms) LIKE ? or LOWER (aliases) LIKE ?',
                   "#{query}%", "%#{query}%", "%#{query}%").limit(ROR_MAX_RESULTS)
      resp.each do |r|
        results << { id: r.ror_id, name: r.name, country: r.country, acronyms: r.acronyms }
      end

      # If we don't have enough results, find matches elsewhere in the name string
      if results.size < ROR_MAX_RESULTS
        resp = where('LOWER(name) LIKE ?', "%#{query}%").limit(ROR_MAX_RESULTS)
        resp.each do |r|
          results << { id: r.ror_id, name: r.name, country: r.country, acronyms: r.acronyms }
        end
      end

      results.flatten.uniq
    end

    # Return the first match for the given name
    # @return a StashEngine::RorOrg or nil
    def self.find_first_by_ror_name(ror_name)
      where(name: ror_name)&.first
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
