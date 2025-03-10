# == Schema Information
#
# Table name: stash_engine_edit_codes
#
#  id         :bigint           not null, primary key
#  applied    :boolean          default(FALSE)
#  edit_code  :string(191)
#  role       :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  author_id  :bigint
#
# Indexes
#
#  index_stash_engine_edit_codes_on_author_id  (author_id)
#  index_stash_engine_edit_codes_on_edit_code  (edit_code)
#
require 'securerandom'

module StashEngine
  class EditCode < ApplicationRecord
    self.table_name = 'stash_engine_edit_codes'
    belongs_to :author, class_name: 'StashEngine::Author'

    enum :role, { submitter: 0, collaborator: 1 }
    before_validation :create_code, unless: :edit_code

    def send_invitation
      StashEngine::UserMailer.invite_author(self).deliver_now
    end

    private

    def create_code
      update(edit_code: SecureRandom.urlsafe_base64(20))
    end
  end
end
