module StashDatacite
  class DataciteDate < ActiveRecord::Base
    self.table_name = 'dcs_dates'
    belongs_to :resource, class_name: StashDatacite.resource_class.to_s

    # the valid method causes errors because it tries to add methods for enum and there is already valid method
    # so need to make it valid_date for symbol for rails not to error!
    DateTypes = Datacite::Mapping::DateType.map(&:value)

    DateTypesEnum = DateTypes.map { |i| [i.downcase.to_sym, i.downcase] }.to_h
                             .select { |k, _v| k != :valid }.merge(valid_date: 'valid')
    DateTypesStrToFull = DateTypes.map { |i| [i.downcase, i] }.to_h

    enum date_type: DateTypesEnum

    # these are hacks around rails method problems.
    def date_type_friendly=(type)
      # self required here to work correctly
      self.date_type = type.to_s.downcase unless type.blank?
    end

    def date_type_friendly
      return nil if date_type.blank?
      return 'Valid' if date_type == 'valid_date' #exception for bad method names
      DateTypesStrToFull[date_type]
    end

    def self.date_type_mapping_obj(str)
      return nil if str.nil?
      Datacite::Mapping::DateType.find_by_value(str)
    end

    def date_type_mapping_obj
      return nil if date_type_friendly.nil?
      DataciteDate.date_type_mapping_obj(date_type_friendly)
    end
  end
end
