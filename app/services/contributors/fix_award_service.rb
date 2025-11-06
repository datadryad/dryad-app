module Contributors
  class FixAwardService
    attr_reader :contributor, :award_details

    def initialize(contributor, award_details)
      @contributor = contributor
      @award_details = award_details
    end

    def call
      existing = find_existing_award
      if existing.any?
        # delete duplicate awards except first
        if existing.count > 1
          pp('DELETE', existing[1..].map { |a| [a.id, a.resource_id] })
          existing[1..].each(&:destroy)
        end

        # update existing contributor with correct data
        update_contributor(existing.last)

        # delete contributor with wrong data
        contributor.destroy
      else
        duplicates = contributor.resource.contributors
          .where(name_identifier_id: contributor.name_identifier_id, award_number: contributor.award_number)
          .where.not(id: contributor.id)
        if duplicates.any?
          pp('DELETE', duplicates.map { |a| [a.id, a.resource_id] })
          duplicates.destroy_all
        end

        update_contributor
      end

      # reindex if needed
      contributor.resource.submit_to_solr if contributor.resource.identifier.pub_state == 'published'
    end

    private

    def find_existing_award
      contributor.resource.funders
        .where(name_identifier_id: award_details[:name_identifier_id], award_number: award_details[:award_number])
        .order(created_at: :desc)
    end

    def update_contributor(contrib = contributor)
      pp "UPDATE: #{contrib.id} with #{contrib.award_number}  from #{contrib.name_identifier_id} to #{award_details[:name_identifier_id]}"
      contrib.update(
        contributor_name: award_details[:contributor_name],
        name_identifier_id: award_details[:name_identifier_id],
        award_number: award_details[:award_number],
        award_title: award_details[:award_title]
      )
    end
  end
end
