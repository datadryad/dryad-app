module StashEngine

  class Organization < ActiveRecord::Base

    validates :identifier, uniqueness: true, allow_blank: true
    validates :name, presence: true, uniqueness: true

    before_validation :nils_to_empty_arrays

    # Serach for an org by name, alias or acronym
    scope :search, ->(pattern) do
      sqlized = "%#{pattern}%"
      where('name LIKE ? OR acronyms LIKE ? OR aliases LIKE ?', sqlized, sqlized, sqlized)
    end

    # Adds the 1st acronym to the name (for autocomplete fields): e.g. `University of California, Berkeley (UCB)`
    def name_with_acronym
      "#{name}#{(acronyms.any? && !name.include?(acronyms.first) ? " (#{acronyms.first})" : '')}"
    end

    # Compares the organization's country to the config list of fee waiver countries
    def fee_waiver_country?
      APP_CONFIG.fee_waiver_countries&.include?(country)
    end

    # acronyms and aliases are returned from ROR as arrays. Just store them as JSON in the
    # database and parse them out to arrays for Ruby
    def acronyms
      JSON.parse(super || [].to_json)
    end

    def acronyms=(array)
      super(array.to_json)
    end

    def aliases
      JSON.parse(super || [].to_json)
    end

    def aliases=(array)
      super(array.to_json)
    end

    private

    # Convert nil values in the JSON array columns to empty arrays before saving
    def nils_to_empty_arrays
      self.acronyms = [] if acronyms.nil?
      self.aliases = [] if aliases.nil?
    end

  end

end
