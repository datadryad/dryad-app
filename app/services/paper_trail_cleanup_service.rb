class PaperTrailCleanupService
  class << self
    def remove_versions_by_resource
      CustomVersion.where(item_type: 'StashEngine::Resource').select(:item_id).distinct.each do |version|
        remove_resource_duplicate_versions(version.item_id)
      end
    end

    # private

    def remove_resource_duplicate_versions(resource_id)
      resource = StashEngine::Resource.with_deleted.find_by(id: resource_id)
      return if resource.nil?

      resource.versions.order(:created_at, :id).each_cons(2) do |a, b|
        if a.additional_info == b.additional_info && (b.object_changes.blank? || a.object_changes == b.object_changes)
          pp "deleting #{b.id}"
          b.destroy
        end
      end
    end

    def remove_versions_by_author
      CustomVersion.where(item_type: 'StashEngine::Author').select(:item_id).distinct.each do |version|
        remove_author_duplicate_versions(version.item_id)
      end
    end

    def remove_author_duplicate_versions(author_id)
      record = StashEngine::Author.find_by(id: author_id)
      return if record.nil?

      record.versions.order(:created_at, :id).each_cons(2) do |a, b|
        if a.additional_info == b.additional_info && (b.object_changes.blank? || a.object_changes == b.object_changes)
          pp "deleting #{b.id}"
          b.destroy
        end
      end
    end
  end
end
