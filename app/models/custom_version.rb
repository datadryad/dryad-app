# == Schema Information
#
# Table name: paper_trail_versions
#
#  id             :bigint           not null, primary key
#  event          :string(191)      not null
#  item_type      :string(191)      not null
#  object         :json
#  object_changes :json
#  whodunnit      :string(191)
#  created_at     :datetime
#  item_id        :string(191)      not null
#  resource_id    :integer
#
# Indexes
#
#  index_paper_trail_versions_on_item_type_and_item_id  (item_type,item_id)
#  index_paper_trail_versions_on_resource_id            (resource_id)
#
class ApplicationVersion < ActiveRecord::Base
  include PaperTrail::VersionConcern
  self.abstract_class = true
end

class CustomVersion < ApplicationVersion
  self.table_name = :paper_trail_versions
end
