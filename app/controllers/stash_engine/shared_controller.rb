module StashEngine
  module SharedController
    require 'uri'
    require 'securerandom'

    def self.included(c)
      c.helper_method :current_tenant, :current_tenant_simple, :current_user, :metadata_engine, :metadata_url_helpers,
                      :metadata_render_path, :stash_url_helpers, :discovery_url_helpers, :landing_url,  :field_suffix,
                      :logo_path, :contact_us_url, :display_br, :display_id, :display_id_plain,
                      :formatted_date, :can_display_embargoed?
    end

    def metadata_url_helpers
      metadata_engine::Engine.routes.url_helpers
    end

    def formatted_date(t)
      return 'Not available' if t.blank?
      t = t.to_time if t.class == String
      t.strftime("%B %e, %Y")
    end

    # generate a render path in the metadata engine
    def metadata_render_path(*args)
      File.join(metadata_engine::Engine.root.to_s.split(File::SEPARATOR).last, args)
    end

    def stash_url_helpers
      StashEngine::Engine.routes.url_helpers
    end

    def discovery_url_helpers
      StashDiscovery::Engine.routes.url_helpers
    end

    # discovery engine isn't namespaced because of blacklight/geoblackight, so "main_app" will work for it.

    # get the current tenant for submission
    def current_tenant
      if current_user
        StashEngine::Tenant.find(current_user.tenant_id)
      elsif session[:test_domain]
        StashEngine::Tenant.by_domain(session[:test_domain])
      else
        StashEngine::Tenant.by_domain(request.host)
      end
    end

    # get the current tenant for display elements, only, ignores logged in
    def current_tenant_display
      if session[:test_domain]
        StashEngine::Tenant.by_domain(session[:test_domain])
      else
        StashEngine::Tenant.by_domain(request.host)
      end
    end

    # get current tenant, only based on the domain
    def current_tenant_simple
      StashEngine::Tenant.by_domain_w_nil(request.host)
    end

    def current_user
      @current_user ||= User.find_by_id(session[:user_id]) if session[:user_id]
    end

    def metadata_engine
      StashEngine.app.metadata_engine.constantize
    end

    def clear_user
      @current_user = nil
    end

    def require_login
      return if current_user
      flash[:alert] = 'You must be logged in.'
      redirect_to current_tenant.try(:omniauth_login_path)
    end

    def require_resource_owner
      if current_user.id != @resource.user_id
        flash[:alert] = 'You do not have permission to modify this dataset.'
        redirect_to stash_engine.dashboard_path
      end
    end

    def can_display_embargoed?(resource)
      !resource.under_embargo? || (current_user && current_user.id == resource.user_id)
    end

    def ajax_require_current_user
      return false unless @current_user
    end

    # this sets up the page variables for use with kaminari paging
    def set_page_info
      @page = params[:page] || '1'
      @page_size = params[:page_size] || '5'
    end

    # helper to generate URL for landing page for an identifier with currently logged-in tenant
    def landing_url(identifier)
      current_tenant.landing_url(stash_url_helpers.show_path(identifier))
    end

    # make suffix number making ids in html forms
    def field_suffix(object)
      if object && object.id
        "_#{object.id}"
      else
        "_#{SecureRandom.uuid}"
      end
    end

    # contact us url
    def contact_us_url
      StashEngine.try(:app).try(:contact_us_uri)
    end

    # make logo_string for image_tag per tenant
    def logo_path(hsh)
      test_path = File.join(Rails.root, 'app', 'assets', 'images', 'tenants')
      base_fn = "logo_#{current_tenant.tenant_id}"
      ['.svg', '.png', '.jpg'].each do |ext|
        if File.exist?(File.join(test_path, "#{base_fn}#{ext}"))
          return view_context.image_tag "tenants/#{base_fn}#{ext}",
                                        hsh.merge(alt: "#{current_tenant.short_name} logo")
        end
      end
    end

    def display_id(type:, my_id:)
      result = StashEngine::LinkGenerator.create_link(type: type, value: my_id)
      if result.class == Array
        view_context.link_to(result.first, result[1], {target: '_blank'})
      else
        "#{type}: #{result}"
      end
    end

    def display_id_plain(type:, my_id:)
      result = StashEngine::LinkGenerator.create_link(type: type, value: my_id)
      if result.class == Array
        result.first
      else
        result
      end
    end

    #function to take a string and make it into html_safe string as paragraphs
    #expanded to also make html links, but really we should be doing this a different
    #way in the long term by having people enter html formatting and then displaying
    #what they actually want instead of guessing at things they typed and trying to
    #display magic html tags based on their textual, non-html.  We could strip it out if something hates html.
    def display_br(str)
      return nil if str.nil?

      # add the awful paragraph junk for BRs and encode since we need to encode manually if we're saying html is safe
      str_arr = str.split(/\< *br *[\/]{0,1} *\>/).reject(&:blank?)
      my_str = str_arr.map{|i| ERB::Util.html_escape(i) }.join(' </p><p> ')

      # kludge in some linking of random URLs they pooped into their text.
      my_str.gsub!(/https?:\/\/\S+/) do |m|
        full_url = Nokogiri::HTML.parse(m).text
        end_punctuation = full_url.match(/[\(\)\.\?\!]+$/).to_s
        full_url = full_url[0..-end_punctuation.length-1]
        "<a href=\"#{full_url}\" title=\"#{full_url}\">" +
            "#{ActionController::Base.helpers.truncate(m)}</a>#{ERB::Util.html_escape(end_punctuation)}"
      end

      # Nokogiri::HTML.parse(escaped).text will give unescaped

      my_str.html_safe
    end
  end
end
