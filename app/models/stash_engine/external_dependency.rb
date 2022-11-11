# frozen_string_literal: true

# Field list:
#    abbreviation, name, description, status, documentation
module StashEngine
  class ExternalDependency < ApplicationRecord
    self.table_name = 'stash_engine_external_dependencies'
    validates :abbreviation, uniqueness: { case_sensitive: false }
    validates :abbreviation, :name, :status, presence: true

    def online?
      @status == 1
    end

    def offline?
      @status == 0
    end

    def troubled?
      @status == 2
    end

    def online
      @status = 1
    end

    def offline
      @status = 0
    end

    def troubled
      @status = 2
    end

  end
end
