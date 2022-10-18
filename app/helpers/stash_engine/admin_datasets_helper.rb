require 'stash/salesforce'

module StashEngine
  module AdminDatasetsHelper

    def sponsor_select
      StashEngine::JournalOrganization.all.map { |item| [item.name, item.id] }
    end

    def status_select(statuses = [])
      statuses = StashEngine::CurationActivity.statuses if statuses.empty?
      statuses.sort { |a, b| a <=> b }.map do |status|
        [StashEngine::CurationActivity.readable_status(status), status]
      end
    end

    def filter_status_select(current_status)
      statuses = StashEngine::CurationActivity.allowed_states(current_status)

      statuses.delete(current_status) # because we don't show the current state as an option, it is implied by leaving state blank

      # makes select list
      status_select(statuses)
    end

    def editor_select
      curators = StashEngine::User.curators
      curators.sort { |a, b| a.last_name.to_s <=> b.last_name.to_s }.map do |c|
        [c.name_last_first, c.id]
      end
    end

    def format_external_references(instring)
      return '' unless instring.present?

      # Turn salesforce references into hyperlinks
      matchdata = instring.match(/(.*)SF ?#? ?(\d+)(.*)/)
      return instring unless matchdata

      sf_link = Stash::Salesforce.case_view_url(case_num: matchdata[2])
      return instring unless sf_link.present?

      render inline: matchdata[1] + link_to("SF #{matchdata[2]}", sf_link, target: :_blank) + matchdata[3]
    end

    def salesforce_links(doi)
      Stash::Salesforce.find_cases_by_doi(doi)
    end
  end
end
