# frozen_string_literal: true

# == Schema Information
#
# Table name: stash_engine_external_dependencies
#
#  id                 :integer          not null, primary key
#  abbreviation       :string(191)
#  name               :string(191)
#  description        :string(191)
#  status             :integer          default(1)
#  documentation      :text(65535)
#  error_message      :text(65535)
#  internally_managed :boolean          default(FALSE)
#  created_at         :datetime
#  updated_at         :datetime
#
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
