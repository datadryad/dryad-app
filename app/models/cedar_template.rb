# == Schema Information
#
# Table name: cedar_templates
#
#  id           :string(191)      not null, primary key
#  template     :json
#  title        :string(191)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  word_bank_id :bigint
#
# Indexes
#
#  index_cedar_templates_on_id            (id)
#  index_cedar_templates_on_word_bank_id  (word_bank_id)
#
# Foreign Keys
#
#  fk_rails_...  (word_bank_id => cedar_word_banks.id)
#
class CedarTemplate < ApplicationRecord
  self.table_name = :cedar_templates

  belongs_to :cedar_word_bank, foreign_key: :word_bank_id
  has_many :cedar_json, foreign_key: :template_id
end
