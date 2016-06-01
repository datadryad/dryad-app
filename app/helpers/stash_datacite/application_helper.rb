require 'securerandom'

module StashDatacite
  module ApplicationHelper
    DEFAULT_TZ = 'America/Los_Angeles'

    def default_time(t)
      local_time(t).strftime('%m/%d/%y %I:%M %p')
    end

    def default_date(t)
      local_time(t).strftime('%m/%d/%y')
    end

    def local_time(t)
      tz = TZInfo::Timezone.get(DEFAULT_TZ)
      tz.utc_to_local(t)
    end

    def unique_form_id(for_object)
      return "edit_#{simple_obj_name(for_object)}_#{for_object.id}" if for_object.id
      "new_#{simple_obj_name(for_object)}_#{SecureRandom.uuid}"
    end

    def simple_obj_name(obj)
      obj.class.to_s.split('::').last.downcase
    end

    # returns the installation id for the rights_uri
    def license_id(uri)
      StashEngine::License.by_uri(uri)[:id]
    end

    # create string for facet limit to subject
    def subject_facet(term)
      "/search?#{CGI.escape('f[dc_subject_sm][]')}=#{CGI.escape(term)}"
    end
  end
end
