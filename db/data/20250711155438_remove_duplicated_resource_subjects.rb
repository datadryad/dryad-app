# frozen_string_literal: true

class RemoveDuplicatedResourceSubjects < ActiveRecord::Migration[8.0]
  def up
    ActiveRecord::Base.transaction do
      before_count = StashDatacite::ResourcesSubjects.select(:resource_id, :subject_id).distinct.count

      duplicates = StashDatacite::ResourcesSubjects.group(:resource_id, :subject_id).having('COUNT(*) > 1').pluck(:resource_id, :subject_id)
      pp "Deleting duplicates for #{duplicates.count} resources ..."

      duplicates.each do |duplicate|
        ids = StashDatacite::ResourcesSubjects.where(resource_id: duplicate[0], subject_id: duplicate[1]).ids
        StashDatacite::ResourcesSubjects.where(id: ids[1..-1]).delete_all
      end

      after_count = StashDatacite::ResourcesSubjects.select(:resource_id, :subject_id).distinct.count
      if before_count != after_count
        pp "Rollback: distinct pair count changed (#{before_count} → #{after_count})"
        raise ActiveRecord::Rollback
      end
    end

  end

  def down
    # raise ActiveRecord::IrreversibleMigration
  end
end
