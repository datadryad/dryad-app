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
#  new_datasets_to_submitted   :integer
#  ppr_size                    :integer
#  ppr_to_curation             :integer
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#
# Indexes
#
#  index_stash_engine_curation_stats_on_date  (date) UNIQUE
#

module StashEngine
  class CurationStats < ApplicationRecord
    self.table_name = 'stash_engine_curation_stats'
    validates :date, presence: true, uniqueness: { case_sensitive: false }

    after_create :recalculate

    def complete?
      datasets_curated.present? &&
        datasets_to_be_curated.present? &&
        datasets_unclaimed.present? &&
        new_datasets.present? &&
        new_datasets_to_submitted.present? &&
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
      populate_new_datasets_to_submitted
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

    def status_on_date(identifier)
      return nil if identifier.created_at > date + 1.day

      curr_status = 'in_progress'
      identifier.curation_activities.each do |ca|
        return curr_status if ca.created_at > date + 1.day

        curr_status = ca.status
      end
      curr_status
    end

    private

    # The number processed (meaning the status changed from 'curation' to 'action_required', 'embargoed' or 'published')
    def populate_datasets_curated
      datasets_found = Set.new
      # for each dataset that received the target status on the given day
      CurationActivity.where(
        created_at: date..(date + 1.day), status: %w[action_required embargoed published to_be_published]
      ).includes(resource: :identifier).find_each do |ca|
        next unless ca&.resource&.identifier

        # if the previous ca was `curation`, add the identifier to datasets_found
        prev_ca = CurationActivity.where(resource_id: ca.resource_id, id: 0..ca.id - 1).last
        datasets_found.add(ca.resource.identifier.id) if prev_ca&.curation?
      end
      update(datasets_curated: datasets_found.size)
    end

    # The number of datasets available for curation on that day,
    # including any held over from before (either have status 'curation' or 'submitted')
    def populate_datasets_to_be_curated
      datasets_found = 0
      unclaimed = 0

      # for each dataset that was in the target status on the given day
      launch_day = Date.new(2019, 9, 17)
      StashEngine::Identifier.where(created_at: launch_day..(date + 1.day))
        .includes(resources: :curation_activities)
        .find_each do |ident|

        # check the actual status on that date...if it was 'curation' or 'submitted', count it
        status = status_on_date(ident)
        next unless %w[submitted curation].include?(status)

        datasets_found += 1
        next if status == 'curation'

        # count as unclaimed if
        #  there is no activity for setting the curator
        #  OR
        #  the last activity for setting the curator is to unsigned
        last_activity = ident.curation_activities.where(created_at: launch_day..(date + 1.day))
          .where("note like 'Changing curator to%' OR note like 'System auto-assigned curator%'")
          .order(id: :asc).last

        unclaimed += 1 if last_activity.nil? || last_activity.note.start_with?('Changing curator to unassigned')
      end
      update(datasets_to_be_curated: datasets_found)
      update(datasets_unclaimed: unclaimed)
    end

    def populate_new_datasets
      update(new_datasets: StashEngine::Identifier.where(created_at: date..(date + 1.day)).count)
    end

    # The number of new submissions that day (so the first time we see them as 'submitted' in the system)
    def populate_new_datasets_to_submitted
      datasets_found = Set.new
      # for each dataset that received the target status on the given day
      CurationActivity.where(created_at: date..(date + 1.day), status: %w[submitted])
        .includes(resource: :identifier).find_each do |ca|

        next unless ca&.resource&.identifier

        found_dataset = ca.resource.identifier
        # skip if the dataset was not first submitted on this date
        next unless found_dataset.first_submitted_resource&.process_date&.submitted&.to_date == date

        datasets_found.add(found_dataset.id) if found_dataset
      end
      update(new_datasets_to_submitted: datasets_found.size)
    end

    # The number of new PPR that day (so the first time we see them as 'peer_review' in the system)
    def populate_new_datasets_to_peer_review
      datasets_found = Set.new
      # for each dataset that received the target status on the given day
      CurationActivity.where(created_at: date..(date + 1.day), status: %w[peer_review])
        .includes(resource: :identifier).find_each do |ca|

        next unless ca&.resource&.identifier

        found_dataset = ca.resource.identifier
        # skip if the dataset was not first submitted on this date
        next unless found_dataset.first_submitted_resource&.process_date&.peer_review&.to_date == date

        datasets_found.add(found_dataset.id) if found_dataset
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
      CurationActivity.where(created_at: date..(date + 1.day), status: to_status)
        .includes(:resource).find_each do |ca|

        next unless ca.resource
        next if datasets_found.include?(ca.resource.identifier_id)

        # if the previous ca was from_status, add the identifier to datasets_found
        prev_ca = CurationActivity.where(resource_id: ca.resource_id, id: 0..(ca.id - 1)).last

        # add to datasets_found if it's transition we want to count
        datasets_found.add(ca.resource.identifier_id) if (from_status.blank? && (prev_ca&.status != ca&.status)) || prev_ca&.status == from_status
      end
      datasets_found.size
    end

    # The number of previously PPR datasets that entered Curation that day
    # Note that this is intended to be more inclusive than other transitions. It includes
    # any dataset in submitted status that was in PPR more recently than it was in a
    # prior curation status.
    def populate_ppr_to_curation
      p2c_count = 0
      # for each dataset that received curation status on the given day
      CurationActivity.where(created_at: date..(date + 1.day), status: 'submitted')
        .includes(resource: [identifier: :curation_activities]).find_each do |ca|

        next unless ca&.resource&.identifier

        # find the most recent PPR or curation status
        # if it's PPR, count it as a ppr_to_curation transition
        ca.resource.identifier.curation_activities
          .where('resource_id < ?', ca.resource_id)
          .order(id: :asc).reverse.each do |sibling_ca|

          if sibling_ca.peer_review?
            p2c_count += 1
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
    # (so they change status from 'action_required' to 'submitted' or previously 'curation')
    def populate_author_revised
      datasets_found = Set.new
      # for each dataset that received the target status on the given day
      CurationActivity.where(created_at: date..(date + 1.day), status: 'submitted')
        .includes(resource: [identifier: :curation_activities])
        .find_each do |ca|

        next unless ca&.resource&.identifier

        # action_required is either a previous status in this version, or the last status of the previous version
        ident = ca.resource.identifier
        next if datasets_found.include?(ident.id)

        this_ver_aar = CurationActivity.where(resource_id: ca.resource_id, id: 0..ca.id - 1, status: 'action_required').present?

        prev_resource = ident.resources.where(id: 0..ca.resource_id - 1).last
        prev_ver_aar = prev_resource&.current_curation_status == 'action_required'

        datasets_found.add(ca.resource.identifier_id) if this_ver_aar || prev_ver_aar
      end

      update(author_revised: datasets_found.size)
    end

    # The number resubmitted that day (were 'published' or 'embargoed' before, and changed status to 'submitted')
    def populate_author_versioned
      datasets_found = Set.new
      # for each dataset that received the target status on the given day
      CurationActivity.where(created_at: date..(date + 1.day), status: 'submitted')
        .includes(resource: %i[identifier process_date]).find_each do |ca|

        next unless ca&.resource&.identifier
        # check if this was the actual date of submission for this resource
        next unless ca.resource.submitted_date&.to_date == date

        # if this dataset has been published or embargoed, count it
        ident = ca.resource.identifier
        next if datasets_found.include?(ident.id)

        datasets_found.add(ident.id) if %w[published embargoed to_be_published].include?(ident.pub_state)
      end

      update(author_versioned: datasets_found.size)
    end

    # The number of datasets that were in STATUS on the date
    def in_status_on_date(status:)
      StashEngine::Resource.latest_per_dataset.joins(:last_curation_activity)
        .where(stash_engine_curation_activities: { status: status, created_at: ..(date + 1.day) })
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
