module StashDatacite
  class Title < ActiveRecord::Base
    self.table_name = 'dcs_titles'
    belongs_to :resource, class_name: StashDatacite.resource_class.to_s

    enum title_type: { main: 'main', subtitle: 'subtitle', alternative_title: 'alternative_title',
                       translated_title: 'translated_title' }

    before_save :strip_whitespace

    private
    def strip_whitespace
      self.title = self.title.strip unless self.title.nil?
    end
  end
end
