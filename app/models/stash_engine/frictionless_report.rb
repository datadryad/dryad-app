# == Schema Information
#
# Table name: stash_engine_frictionless_reports
#
#  id              :bigint           not null, primary key
#  report          :text(4294967295)
#  status          :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  generic_file_id :integer
#
# Indexes
#
#  index_stash_engine_frictionless_reports_on_generic_file_id  (generic_file_id)
#
# Foreign Keys
#
#  fk_rails_...  (generic_file_id => stash_engine_generic_files.id)
#
module StashEngine
  class FrictionlessReport < ApplicationRecord
    self.table_name = 'stash_engine_frictionless_reports'
    belongs_to :generic_file, class_name: 'StashEngine::GenericFile'

    validates_presence_of :generic_file
    validates_presence_of :status

    enum(:status, %w[issues noissues checking error].to_h { |i| [i.to_sym, i] })
  end
end
