# == Schema Information
#
# Table name: stash_engine_curation_stats
#
#  id                          :bigint           not null, primary key
#  aar_size                    :integer
#  author_revised              :integer
#  author_versioned            :integer
#  datasets_curated            :integer
#  datasets_to_aar             :integer
#  datasets_to_be_curated      :integer
#  datasets_to_embargoed       :integer
#  datasets_to_published       :integer
#  datasets_to_withdrawn       :integer
#  datasets_unclaimed          :integer
#  date                        :datetime
#  new_datasets                :integer
#  new_datasets_to_peer_review :integer
#  new_datasets_to_queued      :integer
#  ppr_size                    :integer
#  ppr_to_curation             :integer
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#
# Indexes
#
#  index_stash_engine_curation_stats_on_date  (date) UNIQUE
#

# rubocop:disable Metrics/ClassLength
module StashEngine
  class CurationStats < ApplicationRecord
    self.table_name = 'stash_engine_curation_stats'
    LAUNCH_DATE = Date.new(2019, 9, 17)

    validates :date, presence: true, uniqueness: { case_sensitive: false }

    after_create :recalculate

    def complete?
      datasets_curated.present? &&
        datasets_to_be_curated.present? &&
        datasets_unclaimed.present? &&
        new_datasets.present? &&
        new_datasets_to_queued.present? &&
        new_datasets_to_peer_review.present? &&
        ppr_to_curation.present? &&
        datasets_to_aar.present? &&
        datasets_to_published.present? &&
        datasets_to_embargoed.present? &&
        datasets_to_withdrawn.present? &&
        author_revised.present? &&
        author_versioned.present? &&
        aar_size.present? &&
        ppr_size.present?
    end

    def recalculate
      return unless date

      populate_datasets_curated
      populate_datasets_to_be_curated
      populate_new_datasets
      populate_new_datasets_to_queued
      populate_new_datasets_to_peer_review
      populate_ppr_to_curation
      populate_datasets_to_aar
      populate_datasets_to_published
      populate_datasets_to_embargoed
      populate_datasets_to_withdrawn
      populate_author_revised
      populate_author_versioned
      populate_aar_size
      populate_ppr_size
    end

    def last_identifier_ca_id_per_day(identifier_ids)
      query = StashEngine::CurationActivity.with_deleted.select('identifier_id, MAX(id) AS last_ca_id')
        .where(created_at: LAUNCH_DATE..date.end_of_day)
      query = query.where(identifier_id: identifier_ids) if identifier_ids.present?
      query.group('identifier_id')
    end

    def status_on_date(identifier)
      return nil if identifier.created_at > date + 1.day

      data = last_identifier_ca_id_per_day(identifier.id)
      mapping = data.to_h { |a| [a.identifier_id, a.last_ca_id] }

      StashEngine::CurationActivity.with_deleted.find_by(id: mapping[identifier.id])&.status || 'in_progress'
    end

    def identifiers_with_status(identifiers, status)
      StashEngine::CurationActivity
        .joins("inner join (#{last_identifier_ca_id_per_day(identifiers).to_sql}) as latest on stash_engine_curation_activities.id=last_ca_id")
        .where(status: status, created_at: LAUNCH_DATE..date.end_of_day)
    end

    def identifier_status_on_date(identifier_id)
      latest_per_identifier = last_identifier_ca_id_per_day(identifier_id)
      ca_id = latest_per_identifier[0]&.last_ca_id
      return if ca_id.nil?

      StashEngine::CurationActivity.with_deleted.find_by(id: ca_id)&.status
    end

    # private

    # The number processed (meaning the status changed from 'curation' to 'action_required', 'embargoed', 'published' or 'to_be_published')
    def populate_datasets_curated
      datasets_found = Set.new
      # for each dataset that received the target status on the given day
      CurationActivity.with_deleted
        .where(created_at: date..(date + 1.day), status: %w[action_required embargoed published to_be_published])
        .find_each do |ca|

        # if the previous ca was `curation`, add the identifier to datasets_found
        prev_ca = CurationActivity.with_deleted.where(resource_id: ca.resource_id, id: 0..(ca.id - 1)).last
        datasets_found.add(ca.identifier_id) if prev_ca&.curation?
      end
      update(datasets_curated: datasets_found.size)
    end

    # The number of datasets available for curation on that day,
    # including any held over from before (either have status 'curation' or 'queued')
    def populate_datasets_to_be_curated
      # for each dataset that was in the target status on the given day
      identifiers = StashEngine::Identifier.with_deleted.where(created_at: LAUNCH_DATE..(date + 1.day)).select(:id)
      activities_in_status = identifiers_with_status(identifiers, %w[queued curation])
      to_be_curated = activities_in_status.count

      # all queued datasets
      queued_activities = identifiers_with_status(identifiers, 'queued')

      # there is a curator assignment
      with_assigned_curator_note = CurationActivity.with_deleted.select('identifier_id, MAX(id) AS last_ca_id')
        .where(created_at: LAUNCH_DATE..(date + 1.day), identifier_id: queued_activities.select(:identifier_id))
        .where("note like 'Changing curator to%' OR note like 'System auto-assigned curator%'")
        .group('identifier_id')

      # with unassigned note
      unassigned = StashEngine::CurationActivity
        .joins("inner join (#{with_assigned_curator_note.to_sql}) as latest on stash_engine_curation_activities.id=last_ca_id")
        .where(created_at: LAUNCH_DATE..date.end_of_day)
        .where("note like 'Changing curator to unassigned%'")
        .count

      unclaimed = queued_activities.count - with_assigned_curator_note.size.size + unassigned
      update(datasets_to_be_curated: to_be_curated, datasets_unclaimed: unclaimed)
    end

    def populate_new_datasets
      update(new_datasets: StashEngine::Identifier.with_deleted.where(created_at: date..(date + 1.day)).count)
    end

    # The number of new submissions that day (so the first time we see them as 'queued' in the system)
    def populate_new_datasets_to_queued
      datasets_found = Set.new
      # for each dataset that received the target status on the given day
      CurationActivity.with_deleted.where(created_at: date..(date + 1.day), status: %w[queued]).find_each do |ca|
        next if ca.identifier_id.blank?
        next if datasets_found.include?(ca.identifier_id)

        first_submission = StashEngine::Resource.with_deleted.where(identifier_id: ca.identifier_id)&.submitted&.by_version&.first
        next if first_submission.nil?

        # skip if the dataset was not first queued on this date
        process_date = StashEngine::ProcessDate.with_deleted.find_by(processable_type: 'StashEngine::Resource', processable_id: first_submission.id)
        next unless process_date&.queued&.to_date == date

        datasets_found.add(ca.identifier_id)
      end
      update(new_datasets_to_queued: datasets_found.size)
    end

    # The number of new PPR that day (so the first time we see them as 'peer_review' in the system)
    # Should not include datasets that have been in Submitted or Curated statuses previously.
    def populate_new_datasets_to_peer_review
      datasets_found = Set.new
      # for each dataset that received the target status on the given day
      CurationActivity.with_deleted.where(created_at: date..(date + 1.day), status: %w[peer_review])
        .find_each do |ca|

        next if ca.identifier_id.blank?
        next if datasets_found.include?(ca.identifier_id)

        first_submission = StashEngine::Resource.with_deleted.where(identifier_id: ca.identifier_id).submitted.by_version.first
        next if first_submission.nil?

        # skip if the dataset was not first time in PPR on this date
        process_date = StashEngine::ProcessDate.with_deleted.find_by(processable_type: 'StashEngine::Resource', processable_id: first_submission.id)
        next unless process_date&.peer_review&.to_date == date

        datasets_found.add(ca.identifier_id)
      end
      update(new_datasets_to_peer_review: datasets_found.size)
    end

    # Number that were transitioned directly from one status to another on the target day
    # If from_status is present, only transitions from the given status are counted
    # If from_status is nil, transitions from *any* status are counted
    def datasets_transitioned(from_status: nil, to_status: nil)
      return 0 unless to_status

      datasets_found = Set.new
      # for each dataset that received the target status on the given day
      CurationActivity.with_deleted.where(created_at: date..(date + 1.day), status: to_status).find_each do |ca|
        next if datasets_found.include?(ca.identifier_id)

        # if the previous ca was from_status, add the identifier to datasets_found
        prev_ca = CurationActivity.with_deleted.where(resource_id: ca.resource_id, id: 0..(ca.id - 1)).last

        # add to datasets_found if it's transition we want to count
        datasets_found.add(ca.identifier_id) if (from_status.blank? && (prev_ca&.status != ca&.status)) || prev_ca&.status == from_status
      end
      datasets_found.size
    end

    # The number of previously PPR datasets that entered Curation that day
    # Note that this is intended to be more inclusive than other transitions. It includes
    # any dataset in queued status that was in PPR more recently than it was in a
    # prior curation status.
    def populate_ppr_to_curation
      p2c_count = 0
      # for each dataset that received curation status on the given day
      found = Set.new
      CurationActivity.with_deleted.where(created_at: date..(date + 1.day), status: 'queued').find_each do |ca|
        next if ca.identifier_id.blank?
        next if found.include?(ca.identifier_id)

        # find the most recent PPR or curation status
        # if it's PPR, count it as a ppr_to_curation transition
        CurationActivity.with_deleted
          .where(identifier_id: ca.identifier_id)
          .where('resource_id < ?', ca.resource_id)
          .order(id: :asc).reverse.each do |sibling_ca|

          if sibling_ca.peer_review?
            p2c_count += 1
            found.add(ca.identifier_id)
            break
          elsif sibling_ca.curation?
            break
          end
        end
      end

      update(ppr_to_curation: p2c_count)
    end

    # The number AAR'd that day (status change from 'curation' to 'action_required')
    def populate_datasets_to_aar
      update(datasets_to_aar: datasets_transitioned(from_status: 'curation', to_status: 'action_required'))
    end

    # The number published by a curator that day (status change from 'curation' to 'published' by a curator and not the system)
    def populate_datasets_to_published
      update(datasets_to_published: datasets_transitioned(from_status: 'curation', to_status: 'published'))
    end

    # The number embargoed that day (status change from 'curation' to 'embargoed' per day)
    def populate_datasets_to_embargoed
      update(datasets_to_embargoed: datasets_transitioned(from_status: 'curation', to_status: %w[embargoed to_be_published]))
    end

    # The number withdrawn that day (status change from any status to 'withdrawn')
    def populate_datasets_to_withdrawn
      update(datasets_to_withdrawn: datasets_transitioned(from_status: nil, to_status: 'withdrawn'))
    end

    # The number that come back to us after an Author Action Required
    # (so they change status from 'action_required' to 'queued' or previously 'curation')
    def populate_author_revised
      datasets_found = Set.new
      # for each dataset that received the target status on the given day
      CurationActivity.with_deleted.where(created_at: date..(date + 1.day), status: 'queued')
        .includes(:resource_with_deleted)
        .find_each do |ca|

        next unless ca.identifier_id
        next if datasets_found.include?(ca.identifier_id)

        # action_required is either a previous status in this version, or the last status of the previous version
        if CurationActivity.where(resource_id: ca.resource_id, id: 0..ca.id - 1, status: 'action_required').present?
          datasets_found.add(ca.identifier_id)
          next
        end

        prev_ver_aar = ca.resource_with_deleted.previous_resource&.current_curation_status == 'action_required'

        datasets_found.add(ca.identifier_id) if prev_ver_aar
      end

      update(author_revised: datasets_found.size)
    end

    # The number resubmitted that day (were 'published' or 'embargoed' before, and changed status to 'queued')
    def populate_author_versioned
      datasets_found = Set.new
      # for each dataset that received the target status on the given day
      StashEngine::CurationActivity.with_deleted.where(created_at: date..(date + 1.day), status: 'queued')
        .includes(:identifier_with_deleted, resource_with_deleted: :process_date).find_each do |ca|

        next if ca.identifier_id.blank?
        next if datasets_found.include?(ca.identifier_id)
        # check if this was the actual date of submission for this resource
        next unless ca.resource_with_deleted.queued_date&.to_date == date

        # if this dataset has been published or embargoed, count it
        ident = ca.identifier_with_deleted
        next if ident.nil?

        datasets_found.add(ca.identifier_id) if %w[published embargoed to_be_published].include?(ident.pub_state)
      end

      update(author_versioned: datasets_found.size)
    end

    # The number of datasets that were in STATUS on the date
    def in_status_on_date(status:)
      latest_per_identifier = StashEngine::CurationActivity.with_deleted.select('identifier_id, MAX(id) AS last_ca_id')
        .where(created_at: LAUNCH_DATE..date.end_of_day)
        .group('identifier_id')

      StashEngine::CurationActivity
        .joins("inner join (#{latest_per_identifier.to_sql}) as latest on stash_engine_curation_activities.id=last_ca_id")
        .where(status: status, created_at: LAUNCH_DATE..date.end_of_day)
        .count
    end

    def populate_aar_size
      update(aar_size: in_status_on_date(status: 'action_required'))
    end

    def populate_ppr_size
      update(ppr_size: in_status_on_date(status: 'peer_review'))
    end

  end
end
# rubocop:enable Metrics/ClassLength
