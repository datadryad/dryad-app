# CurationStats stores statistics about the submission/curation process
# that rarely change and take a little time to calculate. This class may only be
# instantiated once for each date. Rather than instantiating with `new` or `create`,
# it is preferred to use `find_or_create_by(date: <somedate>)`.

module StashEngine
  class CurationStats < ApplicationRecord
    self.table_name = 'stash_engine_curation_stats'
    validates :date, presence: true, uniqueness: { case_sensitive: false }

    after_create :recalculate

    def complete?
      datasets_curated.present? &&
        datasets_to_be_curated.present? &&
        new_datasets_to_submitted.present? &&
        new_datasets_to_peer_review.present? &&
        ppr_to_curation.present? &&
        datasets_to_aar.present? &&
        datasets_to_published.present? &&
        datasets_to_embargoed.present? &&
        datasets_to_withdrawn.present? &&
        author_revised.present? &&
        author_versioned.present?
    end

    def recalculate
      return unless date

      populate_datasets_curated
      populate_datasets_to_be_curated
      populate_new_datasets_to_submitted
      populate_new_datasets_to_peer_review
      populate_ppr_to_curation
      populate_datasets_to_aar
      populate_datasets_to_published
      populate_datasets_to_embargoed
      populate_datasets_to_withdrawn
      populate_author_revised
      populate_author_versioned
    end

    def status_on_date(identifier)
      return nil if identifier.created_at > date + 1.day

      curr_status = 'in_progress'
      identifier&.resources&.map(&:curation_activities)&.flatten&.each do |ca|
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
      cas = CurationActivity.where(created_at: date..(date + 1.day), status: %w[action_required embargoed published])
      cas.each do |ca|
        next unless ca.resource

        # if the previous ca was `curation`, add the identifier to datasets_found
        prev_ca = CurationActivity.where(resource_id: ca.resource_id, id: 0..ca.id - 1).last
        datasets_found.add(ca.resource.identifier) if prev_ca&.curation?
      end
      update(datasets_curated: datasets_found.size)
    end

    # The number of datasets available for curation on that day,
    # including any held over from before (either have status 'curation' or 'submitted')
    def populate_datasets_to_be_curated
      datasets_found = 0

      # for each dataset that was in the target status on the given day
      launch_day = Date.new(2019, 9, 17)

      StashEngine::Identifier.where(created_at: launch_day..(date + 1.day)).each do |i|
        # check the actual status on that date...if it was 'curation' or 'submitted', count it
        s = status_on_date(i)
        datasets_found += 1 if %w[submitted curation].include?(s)
      end
      update(datasets_to_be_curated: datasets_found)
    end

    # The number of new submissions that day (so the first time we see them as 'submitted' in the system)
    def populate_new_datasets_to_submitted
      datasets_found = Set.new
      # for each dataset that received the target status on the given day
      cas = CurationActivity.where(created_at: date..(date + 1.day), status: %w[submitted])
      cas.each do |ca|
        # include this dataset unless it has a previous resource that had been submitted
        this_resource = ca.resource
        found_dataset = this_resource&.identifier
        next unless found_dataset

        prev_resources = this_resource.identifier.resources.where(id: 0..this_resource.id - 1)
        prev_resources.each do |pr|
          found_dataset = nil if pr.submitted_date
        end

        datasets_found.add(found_dataset) if found_dataset
      end
      update(new_datasets_to_submitted: datasets_found.size)
    end

    # The number of new PPR that day (so the first time we see them as 'peer_review' in the system)
    def populate_new_datasets_to_peer_review
      datasets_found = Set.new
      # for each dataset that received the target status on the given day
      cas = CurationActivity.where(created_at: date..(date + 1.day), status: %w[peer_review])
      cas.each do |ca|
        prev_ca = CurationActivity.where(resource_id: ca.resource_id, id: 0..ca.id - 1).last
        # don't count reminder statuses or other minor updates
        next if prev_ca&.peer_review? || ca.note&.include?('peer_review_reminder') || ca.note&.include?('notification sent to author')

        # include this dataset unless it has a previous resource that had been submitted
        this_resource = ca.resource
        next unless this_resource

        found_dataset = this_resource.identifier
        prev_resources = this_resource.identifier.resources.where(id: 0..this_resource.id - 1)
        prev_resources.each do |pr|
          found_dataset = nil if pr.submitted_date
        end

        datasets_found.add(found_dataset) if found_dataset
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
      cas = CurationActivity.where(created_at: date..(date + 1.day), status: to_status)
      cas.each do |ca|
        next unless ca.resource

        # if the previous ca was from_status, add the identifier to datasets_found
        prev_ca = CurationActivity.where(resource_id: ca.resource_id, id: 0..ca.id - 1).last

        # add to datasets_found if it's transition we want to count
        if (from_status.blank? && (prev_ca&.status != ca&.status)) ||
           prev_ca&.status == from_status
          datasets_found.add(ca.resource.identifier)
        end
      end
      datasets_found.size
    end

    # The number of previously PPR datasets that entered Curation that day
    # Note that this is intended to be more inclusive than other transitions. It includes
    # any dataset entering Curation status that was in PPR more recently than it was in a
    # prior curation status.
    def populate_ppr_to_curation
      p2c_count = 0
      # for each dataset that received curation status on the given day
      cas = CurationActivity.where(created_at: date..(date + 1.day), status: 'curation')
      cas.each do |ca|
        # find the most recent PPR or curation status
        # if it's PPR, count it as a ppr_to_curation transition
        # if it's curation, or we get to the end of the list, don't count it
        ca.resource&.identifier&.resources&.map(&:curation_activities)&.flatten&.reverse&.each do |sibling_ca|
          next if sibling_ca.id >= ca.id

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
      update(datasets_to_embargoed: datasets_transitioned(from_status: 'curation', to_status: 'embargoed'))
    end

    # The number withdrawn that day (status change from any status to 'withdrawn')
    def populate_datasets_to_withdrawn
      update(datasets_to_withdrawn: datasets_transitioned(from_status: nil, to_status: 'withdrawn'))
    end

    # The number that come back to us after an Author Action Required
    # (so they change status from 'action_required' to 'curation')
    def populate_author_revised
      datasets_found = Set.new
      # for each dataset that received the target status on the given day
      cas = CurationActivity.where(created_at: date..(date + 1.day), status: 'curation')
      cas.each do |ca|
        # action_required is either a previous status in this version, or the last status of the previous version
        this_ver_aar = CurationActivity.where(resource_id: ca.resource_id, id: 0..ca.id - 1, status: 'action_required').present?
        ident = ca.resource&.identifier
        next unless ident

        prev_resource = ident.resources.where(id: 0..ca.resource_id - 1).last
        prev_ver_aar = prev_resource&.current_curation_status == 'action_required'

        datasets_found.add(ca.resource.identifier) if this_ver_aar || prev_ver_aar
      end

      update(author_revised: datasets_found.size)
    end

    # The number resubmitted that day (were 'published' or 'embargoed' before, and changed status to 'submitted')
    def populate_author_versioned
      datasets_found = Set.new
      # for each dataset that received the target status on the given day
      cas = CurationActivity.where(created_at: date..(date + 1.day), status: 'submitted')
      cas.each do |ca|
        # if this dataset has been published or embargoed, count it
        ident = ca.resource&.identifier
        next unless ident

        datasets_found.add(ident) if %w[published embargoed].include?(ident.pub_state)
      end

      update(author_versioned: datasets_found.size)
    end

  end
end
