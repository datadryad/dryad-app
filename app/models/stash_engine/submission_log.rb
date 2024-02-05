# == Schema Information
#
# Table name: stash_engine_submission_logs
#
#  id                         :integer          not null, primary key
#  archive_response           :text(65535)
#  archive_submission_request :text(65535)
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  resource_id                :integer
#
# Indexes
#
#  index_stash_engine_submission_logs_on_resource_id  (resource_id)
#
module StashEngine
  class SubmissionLog < ApplicationRecord
    self.table_name = 'stash_engine_submission_logs'
  end
end
