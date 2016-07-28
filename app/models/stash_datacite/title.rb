module StashDatacite
  class Title < ActiveRecord::Base
    self.table_name = 'dcs_titles'
    belongs_to :resource, class_name: StashDatacite.resource_class.to_s

    TitleTypes = %w(AlternativeTitle Subtitle TranslatedTitle)

    TitleTypesEnum = TitleTypes.map{|i| [i.downcase.to_sym, i.downcase]}.to_h
    TitleTypesStrToFull = TitleTypes.map{|i| [i.downcase, i]}.to_h

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

    private
    def strip_whitespace
      self.title = self.title.strip unless self.title.nil?
    end
  end
end
