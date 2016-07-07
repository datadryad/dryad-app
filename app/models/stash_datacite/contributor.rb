module StashDatacite
  class Contributor < ActiveRecord::Base
    self.table_name = 'dcs_contributors'
    belongs_to :resource, class_name: StashDatacite.resource_class.to_s
    belongs_to :name_identifier

    enum contributor_type: { funder: 'funder' }

    before_save :strip_whitespace

    private
    def strip_whitespace
      self.contributor_name = self.contributor_name.strip unless self.contributor_name.nil?
      self.award_number =  self.award_number.strip unless self.award_number.nil?
    end
  end
end
