# frozen_string_literal: true

# == Schema Information
#
# Table name: dcs_descriptions
#
#  id               :integer          not null, primary key
#  description      :text(16777215)
#  description_type :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  resource_id      :integer
#
# Indexes
#
#  index_dcs_descriptions_on_resource_id  (resource_id)
#
module StashDatacite
  class Description < ApplicationRecord
    self.table_name = 'dcs_descriptions'
    has_paper_trail

    belongs_to :resource, class_name: StashEngine::Resource.to_s

    DescriptionTypes = Datacite::Mapping::DescriptionType.map(&:value)

    DescriptionTypesEnum = DescriptionTypes.to_h { |i| [i.downcase.to_sym, i.downcase] }
    DescriptionTypesStrToFull = DescriptionTypes.to_h { |i| [i.downcase, i] }

    # GrantRegex = Regexp.new(/^Data were created with funding from (.+) under grant (.+)$/)

    # enum :description_type, DescriptionTypesEnum

    # scopes for description_type
    scope :type_abstract, -> { where(description_type: 'abstract') }
    scope :type_methods, -> { where(description_type: 'methods') }
    scope :type_technical_info, -> { where(description_type: 'technicalinfo') }
    scope :type_other, -> { where(description_type: 'other') }

    # the xml description type for DataCite when we've excluded our special sauce

    def description_type_friendly=(type)
      self.description_type = type.to_s.downcase unless type.blank?
    end

    def description_type_friendly
      return nil if description_type.blank?

      DescriptionTypesStrToFull[description_type]
    end

    def self.description_type_mapping_obj(str)
      return nil if str.nil?

      Datacite::Mapping::DescriptionType.find_by_value(str)
    end

    def description_type_mapping_obj
      return nil if description_type_friendly.nil?

      Description.description_type_mapping_obj(description_type_friendly)
    end

    def update_search_words
      resource&.identifier&.update_search_words! if description_type == 'abstract' && saved_change_to_description?
    end

    after_save :update_search_words
  end
end
