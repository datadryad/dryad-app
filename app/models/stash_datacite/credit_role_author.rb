# == Schema Information
#
# Table name: dcs_credit_roles_authors
#
#  id             :bigint           not null, primary key
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  author_id      :integer
#  credit_role_id :integer
#
# Indexes
#
#  index_dcs_credit_roles_authors_on_author_id       (author_id)
#  index_dcs_credit_roles_authors_on_credit_role_id  (credit_role_id)
#
module StashDatacite
  class CreditRoleAuthor < ApplicationRecord
    self.table_name = 'dcs_credit_roles_authors'

    belongs_to :credit_role, class_name: 'StashDatacite::CreditRole', foreign_key: 'credit_role_id'
    belongs_to :author, class_name: 'StashEngine::Author', foreign_key: 'author_id'
  end
end
