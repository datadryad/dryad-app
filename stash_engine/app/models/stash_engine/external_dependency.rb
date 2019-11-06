# frozen_string_literal: true

# Field list:
#    abbreviation, name, description, status, documentation
module StashEngine
  class ExternalDependency < ActiveRecord::Base

    validates :abbreviation, uniqueness: true
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
