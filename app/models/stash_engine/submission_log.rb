# == Schema Information
#
# Table name: stash_engine_submission_logs
#
#  id                         :integer          not null, primary key
#  resource_id                :integer
#  archive_response           :text(65535)
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  archive_submission_request :text(65535)
#
module StashEngine
  class SubmissionLog < ApplicationRecord
    self.table_name = 'stash_engine_submission_logs'
  end
end
