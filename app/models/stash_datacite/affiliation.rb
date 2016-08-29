module StashDatacite
  class Affiliation < ActiveRecord::Base
    self.table_name = 'dcs_affiliations'
    has_and_belongs_to_many :creators, class_name: 'StashDatacite::Creator'
    has_and_belongs_to_many :contributors, class_name: 'StashDatacite::Contributor'

    before_save :strip_whitespace

    private

    def strip_whitespace
      self.long_name = long_name.strip unless long_name.nil?
    end
  end
end
