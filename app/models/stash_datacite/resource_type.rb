module StashDatacite
  class ResourceType < ActiveRecord::Base
    self.table_name = 'dcs_resource_types'
    belongs_to :resource, class_name: StashDatacite.resource_class.to_s

    ResourceTypes = %w(Audiovisual Collection Dataset Event Image InteractiveResource Model PhysicalObject Service
                      Software Sound Text Workflow Other)

    ResourceTypeEnum = ResourceTypes.map{|i| [i.downcase.to_sym, i.downcase]}.to_h
    ResourceTypesStrToFull = ResourceTypes.map{|i| [i.downcase, i]}.to_h


    # odd ones out here are Spreadsheet, Video, Multiple Types and are only for UI display

    ResourceTypesLimited = { Spreadsheet: 'dataset', Image: 'image', Sound: 'sound', Video: 'audiovisual',
                             Text: 'text', Software: 'software', :"Multiple Types" => 'collection', Other: 'other' }

    enum resource_type: ResourceTypeEnum

    def resource_type_friendly=(type)
      # self required here to work correctly
      self.resource_type = type.to_s.downcase unless type.blank?
    end

    def resource_type_friendly
      return nil if resource_type.blank?
      ResourceTypesStrToFull[resource_type]
    end

    def resource_type_ui
      return nil if resource_type.blank?
      ResourceTypesLimited.invert[resource_type].to_s
    end

  end
end
