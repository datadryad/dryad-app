module StashEngine
  module ApplicationHelper
    def title(resource)
      unless resource.nil?
        @titles.where(resource_id: resource.id).pluck(:title).join(" ")
      else
        "unknown"
      end
    end
  end
end
