module StashDatacite
  class ResourceType < ActiveRecord::Base
    self.table_name = 'dcs_resource_types'
    belongs_to :resource, class_name: StashDatacite.resource_class.to_s

    enum resource_type: { Spreadsheet: 'dataset', Image: 'image', Sound: 'sound', Video: 'audiovisual',
                          Text: 'text', Software: 'software', :"Multiple Types" => 'collection', Other: 'other' }
  end
end
