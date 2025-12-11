# == Schema Information
#
# Table name: cedar_word_banks
#
#  id         :bigint           not null, primary key
#  keywords   :text(65535)
#  label      :string(191)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class CedarWordBank < ApplicationRecord
  self.table_name = :cedar_word_banks

  validates :label, presence: true, uniqueness: { case_sensitive: false }
  has_many :cedar_templates, foreign_key: :word_bank_id
end
