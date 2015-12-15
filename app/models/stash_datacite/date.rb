module StashDatacite
  class Date < ActiveRecord::Base
    self.table_name = 'dcs_dates'
    belongs_to :resource, class_name: StashDatacite.resource_class.to_s

    enum date_type: { accepted: 'accepted', available: 'available', copyrighted: 'copyrighted',
                      collected: 'collected', created: 'created', issued: 'issued',
                      submitted: 'submitted', updated: 'updated', valid: 'valid_date' }
  end
end
