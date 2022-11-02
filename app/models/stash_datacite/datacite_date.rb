# frozen_string_literal: true

module StashDatacite
  class DataciteDate < ApplicationRecord
    self.table_name = 'dcs_dates'
    belongs_to :resource, class_name: StashEngine::Resource.to_s

    # the valid method causes errors because it tries to add methods for enum and there is already valid method
    # so need to make it valid_date for symbol for rails not to error!
    DateTypes = Datacite::Mapping::DateType.map(&:value)

    DateTypesEnum = DateTypes.to_h { |i| [i.downcase.to_sym, i.downcase] }
      .reject { |k, _v| k == :valid }.merge(valid_date: 'valid')
    DateTypesStrToFull = DateTypes.to_h { |i| [i.downcase, i] }

    enum date_type: DateTypesEnum

    # with enum the types are automatically scopes such as available
    # scope :available, -> { where(date_type: 'available')}

    # these are hacks around rails method problems.
    def date_type_friendly=(type)
      # self required here to work correctly
      self.date_type = type.to_s.downcase unless type.blank?
    end

    def date_type_friendly
      return nil if date_type.blank?
      return 'Valid' if date_type == 'valid_date' # exception for bad method names

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

    def self.set_date_available(resource_id:)
      resource = StashEngine::Resource.find(resource_id)
      publication_date = resource.publication_date
      return unless publication_date

      date_available = find_or_create_by(resource_id: resource_id, date_type: 'available')
      date_available.date = publication_date.utc.iso8601
      date_available.save
      date_available
    end
  end
end
