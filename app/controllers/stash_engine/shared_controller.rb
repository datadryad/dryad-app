require 'rails_rinku'
require 'nokogiri'

module StashEngine
  module SharedController # rubocop:disable Metrics/ModuleLength
    DEFAULT_TZ = 'UTC'.freeze

    require 'uri'
    require 'securerandom'

    def self.included(c)
      c.helper_method \
        %i[
          metadata_url_helpers metadata_render_path stash_url_helpers contact_us_url logo_path
          formatted_date formatted_datetime formatted_html5_date local_time default_date
          current_tenant current_user
          field_suffix shorten_linked_url english_list
          display_id display_id_plain display_author_orcid
          display_br link_urls!
        ]
    end

    # ----------------------
    # URL/Path generation
    # ----------------------

    def metadata_url_helpers
      Rails.application.routes.url_helpers
    end

    # generate a render path in the metadata engine
    def metadata_render_path(*args)
      File.join('stash_datacite', args)
    end

    def stash_url_helpers
      Rails.application.routes.url_helpers
    end

    # helper to generate URL for landing page for an identifier with currently logged-in tenant
    def landing_url(identifier)
      current_tenant.full_url(stash_url_helpers.show_path(identifier))
    end

    # contact us url
    def contact_us_url
      StashEngine.try(:app).try(:contact_us_uri)
    end

    # make logo_string for image_tag per tenant
    def logo_path(hsh)
      view_context.image_tag "tenants/#{current_tenant.logo_file}", hsh.merge(alt: " #{current_tenant.short_name}")
    end

    # ----------------------
    # Formatted Date/Times
    # ----------------------

    def formatted_date(t)
      return 'Not available' if t.blank?

      t = t.to_time if t.instance_of?(String)
      local_time(t)&.strftime('%B %e, %Y')
    end

    def formatted_datetime(t)
      return 'Not available' if t.blank?

      t = t.to_time if t.instance_of?(String)
      local_time(t)&.strftime('%m/%d/%Y %H:%M:%S %Z')
    end

    def formatted_html5_date(t)
      return 'Not available' if t.blank?

      t = t.to_time if t.instance_of?(String)
      local_time(t)&.strftime('%Y-%m-%d')
    end

    def local_time(t)
      tz = TZInfo::Timezone.get(DEFAULT_TZ)
      tz.utc_to_local(t)
    end

    def default_date(t)
      return '' unless t.is_a? Time

      local_time(t)&.strftime('%m/%d/%y')
    end

    # ----------------------
    # Current state: tenant & user
    # ----------------------

    # get the current tenant for submission
    def current_tenant
      if current_user && current_user.tenant_id.present?
        StashEngine::Tenant.find(current_user.tenant_id)
      else
        StashEngine::Tenant.find(APP_CONFIG.default_tenant)
      end
    end

    def current_user
      # without the StashEngine namespace in the following line, Rails does something janky with dynamic reloading for
      # development environments and it sometimes finds no users
      @current_user ||= StashEngine::User.find_by_id(session[:user_id]) if session[:user_id]
    end

    def clear_user
      @current_user = nil
    end

    # ----------------------
    # Before Action: basic setup for controllers
    # ----------------------

    # this sets up the page variables for use with kaminari paging
    def set_page_info
      @page = params[:page] || '1'
      @page_size = params[:page_size] || '5'
    end

    # gets the resource if @resource has been set or params[:resource_id] is present, used many places
    # if we need to set something else as resource, set the @resource first in filters
    def default_resource
      return nil unless @resource || params[:resource_id]

      @resource ||= StashEngine::Resource.find(params[:resource_id])
    end

    # ----------------------
    # Security Information methods
    # ----------------------

    # ----------------------
    # Generation of items for use in HTML pages (only?)
    # ----------------------

    # make unique id for an object to be used in html
    def field_suffix(object)
      if object && object.id
        "_#{object.id}"
      else
        "_#{SecureRandom.uuid}"
      end
    end

    # Make URLs short and pretty
    def shorten_linked_url(url:, length: 80)
      return '' if url.blank?

      "<a href=\"#{url}\" title=\"#{ERB::Util.html_escape(url)}\">#{ERB::Util.html_escape(url.ellipsisize(length))}</a>".html_safe
    end

    # an english list of items with the conjunction between the final pair, if needed.  Conjunction would be 'and' or
    # 'or' usually
    def english_list(array:, conjunction:)
      return '' if array.empty?
      return array.first if array.length == 1

      "#{array[0..-2].join(', ')} #{conjunction} #{array.last}"
    end

    # ----------------------
    # Displaying identifiers in many different and annoying ways
    # ----------------------

    # try to display identifiers linked, but if if not, then just display what you can
    def display_id(type:, my_id:)
      result = StashEngine::LinkGenerator.create_link(type: type, value: my_id)
      if result.instance_of?(Array)
        view_context.link_to(result.first, result[1], target: '_blank')
      else
        "#{type}: #{result}"
      end
    end

    # display some random identifier in plan text, not linked
    def display_id_plain(type:, my_id:)
      result = StashEngine::LinkGenerator.create_link(type: type, value: my_id)
      if result.instance_of?(Array)
        result.first
      else
        result
      end
    end

    # Pretty orcids based on sandbox or not?
    def display_author_orcid(author)
      if APP_CONFIG.orcid.site == 'https://sandbox.orcid.org/'
        view_context.link_to("https://sandbox.orcid.org/#{author.author_orcid}",
                             "https://sandbox.orcid.org/#{author.author_orcid}",
                             target: '_blank', class: 'c-orcid__id').html_safe
      else
        view_context.link_to("https://orcid.org/#{author.author_orcid}",
                             "https://orcid.org/#{author.author_orcid}",
                             target: '_blank', class: 'c-orcid__id').html_safe
      end
    end

    # ----------------------
    # Paragraph kludging and URL auto-linking for poopy plain text that has delusions of grandeur
    # ----------------------

    # function to take a string and make it into html_safe string as paragraphs
    # expanded to also make html links, but really we should be doing this a different
    # way in the long term by having people enter html formatting and then displaying
    # what they actually want instead of guessing at things they typed and trying to
    # display magic html tags based on their textual, non-html.  We could strip it out if something hates html.
    def display_br(str)
      return nil if str.nil?

      # add the awful paragraph junk for BRs and encode since we need to encode manually if we're saying html is safe
      str_arr = str.split(%r{< *br */{0,1} *>}).reject(&:blank?)
      my_str = str_arr.map { |i| ERB::Util.html_escape(i) }.join(' </p><p> ')
      my_str = link_urls(my_str)
      my_str.html_safe
    end

    # kludge in some linking of random URLs they pooped into their text.
    def link_urls(my_str)
      out = ActionController::Base.helpers.auto_link(my_str, html: { target: '_blank' }) do |text|
        ActionController::Base.helpers.truncate(text, length: 60)
        # text.ellipsisize(80)
      end
      # We need to add the title attribute with the full URL so people can see the full url with hover on most browser if they like
      # unfortunately, rinku doesn't allow a dynamic title attribute to be easily added that is based on the href value, so Nokogiri
      doc = Nokogiri::HTML::DocumentFragment.parse(out)
      doc.css('a').each do |link|
        link['title'] = link.attributes['href'].value
      end
      doc.to_s
    end

  end
end
