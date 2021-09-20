module StashEngine
  module AdminDatasetsHelper

    def institution_select
      StashEngine::Tenant.all.map { |item| [item.short_name, item.tenant_id] }
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
      curators.sort { |a, b| a.last_name <=> b.last_name }.map do |c|
        [c.name, c.id]
      end
    end

    def format_external_references(instring)
      return '' unless instring.present?

      # Turn salesforce references into hyperlinks
      matchdata = instring.match(/(.*)SF ?#? ?(\d+)(.*)/)
      return instring unless matchdata

      render inline: matchdata[1] + link_to("SF #{matchdata[2]}", salesforce_link(case_num: matchdata[2])) + matchdata[3]
    end

    def salesforce_link(case_num: '')
      # @sf.query("SELECT Id FROM Case Where CaseNumber = '00006729'").first['Id']
      
      "https#{case_id}"
    end
  end
end
