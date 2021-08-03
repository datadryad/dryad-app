class UpdateRelatedIdentifierTypes < ActiveRecord::Migration[5.2]
  def change
    StashDatacite::RelatedIdentifier.where(work_type: :article).group_by(&:resource_id).each do |_resource_id, ri|
      ri.first.update(work_type: :primary_article)
    end
  end
end
