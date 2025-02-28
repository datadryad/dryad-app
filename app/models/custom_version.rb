class ApplicationVersion < ActiveRecord::Base
  include PaperTrail::VersionConcern
  self.abstract_class = true
end

class CustomVersion < ApplicationVersion
  self.table_name = :paper_trail_versions
end
