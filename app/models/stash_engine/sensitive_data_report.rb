# == Schema Information
#
# Table name: stash_engine_sensitive_data_reports
#
#  id              :bigint           not null, primary key
#  report          :text(65535)
#  status          :string(191)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  generic_file_id :integer
#
# Indexes
#
#  index_stash_engine_sensitive_data_reports_on_generic_file_id  (generic_file_id)
#
# Foreign Keys
#
#  fk_rails_...  (generic_file_id => stash_engine_generic_files.id)
#
module StashEngine
  class SensitiveDataReport < ApplicationRecord
    self.table_name = 'stash_engine_sensitive_data_reports'
    belongs_to :generic_file, class_name: 'StashEngine::GenericFile'

    validates_presence_of :generic_file
    validates_presence_of :status

    enum(:status, %w[issues noissues checking error].to_h { |i| [i.to_sym, i] })

    def report
      JSON.parse(super) if super.present?
    end
  end
end
