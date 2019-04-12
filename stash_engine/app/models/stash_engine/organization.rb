module StashEngine

  class Organization < ActiveRecord::Base

    validates :identifier, uniqueness: true, allow_blank: true
    validates :name, presence: true, uniqueness: true

    def name_for_autocomplete
      "#{name}#{(acronyms.any? && !name.include?(acronyms.first) ? " (#{acronyms.first})" : '')}"
    end

    def fee_waiver_country?
      APP_CONFIG.fee_waiver_countries&.include?(country)
    end

    def acronyms
      JSON.parse(super)
    end
    def acronyms=(array)
      super(array.to_json)
    end

    def aliases
      JSON.parse(super)
    end
    def aliases=(array)
      super(array.to_json)
    end

  end

end
