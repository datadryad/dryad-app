# frozen_string_literal: true

module StashDatacite
  class ResourceType < ApplicationRecord
    self.table_name = 'dcs_resource_types'
    belongs_to :resource, class_name: StashEngine::Resource.to_s

    ResourceTypesGeneral = Datacite::Mapping::ResourceTypeGeneral.map(&:value)

    ResourceTypeGeneralEnum = ResourceTypesGeneral.to_h { |i| [i.downcase.to_sym, i.downcase] }
    ResourceTypesGeneralStrToFull = ResourceTypesGeneral.to_h { |i| [i.downcase, i] }

    # Only for UI display
    # rubocop:disable Naming/ConstantName
    ResourceTypesGeneralLimited = { Dataset: 'dataset', Image: 'image', Sound: 'sound', Video: 'audiovisual',
                                    Text: 'text', Software: 'software', Collection: 'collection', Other: 'other' }.freeze
    # rubocop:enable Naming/ConstantName

    # WARNING: The enum here is defined with the prefix `rtg`, to ensure the `model` enum value does
    # not generate a `model` method that would conflict with the method in ActiveRecord. If you want to
    # use the automatically-generated methods for working with enums, you must include the prefix,
    # such as `my_resource_type.rtg_dataset?` or `my_resource_type.rtg_software!`
    enum resource_type_general: ResourceTypeGeneralEnum, _prefix: :rtg

    def resource_type_general_friendly
      return nil if resource_type_general.blank?

      ResourceTypesGeneralStrToFull[resource_type_general]
    end

    def resource_type_general_ui
      return nil if resource_type_general.blank?

      ResourceTypesGeneralLimited.invert[resource_type_general].to_s
    end

    def self.resource_type_general_mapping_obj(str)
      return nil if str.nil?

      Datacite::Mapping::ResourceTypeGeneral.find_by_value(str)
    end

    def resource_type_general_mapping_obj
      return nil if resource_type_general_friendly.nil?

      ResourceType.resource_type_general_mapping_obj(resource_type_general_friendly)
    end
  end
end
