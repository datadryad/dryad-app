class CounterLog < ActiveRecord::Base
  self.table_name = 'counter_log'
  self.primary_key = 'id'
end