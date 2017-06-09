module StashDatacite
  class Title < ActiveRecord::Base
    self.table_name = 'dcs_titles'
    belongs_to :resource, class_name: StashEngine::Resource.to_s

    TitleTypes = Datacite::Mapping::TitleType.map(&:value)

    TitleTypesEnum = TitleTypes.map { |i| [i.downcase.to_sym, i.downcase] }.to_h
    TitleTypesStrToFull = TitleTypes.map { |i| [i.downcase, i] }.to_h

    enum title_type: TitleTypesEnum

    before_save :strip_whitespace

    def title_type_friendly=(type)
      if type.blank?
        self.title_type = nil
        return
      end
      self.title_type = type.to_s.downcase
    end

    def title_type_friendly
      return nil if title_type.blank?
      TitleTypesStrToFull[title_type]
    end

    def self.title_type_mapping_obj(str)
      return nil if str.blank?
      Datacite::Mapping::TitleType.find_by_value(str)
    end

    def title_type_mapping_obj
      return nil if title_type_friendly.nil?
      Title.title_type_mapping_obj(title_type_friendly)
    end

    private

    def strip_whitespace
      self.title = title.strip unless title.nil?
    end
  end
end
