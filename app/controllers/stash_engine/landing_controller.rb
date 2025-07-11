require 'securerandom'

module StashEngine
  class LandingController < ApplicationController
    # LandingMixin should provide:
    # - has_geolocation?
    include StashDatacite::LandingMixin

    before_action :require_identifier_and_resource, only: %i[show linkset]
    protect_from_forgery(except: [:update])

    # ############################################################
    # Helper methods

    def id
      @id ||= identifier_from(params)
    end

    helper_method :id

    # -- gets the resource for display from the identifier --
    # some users get to see more than the public such as owners, curators, admins
    def resource
      return @resource unless @resource.nil?

      @user_type = 'public'
      res = id.resources.submitted&.by_version_desc&.first
      return res if res.nil? # no submitted resources

      @resource = if (owner?(resource: res) || admin?(resource: res)) && !params.key?(:public)
                    @user_type = 'privileged'
                    id.resources.submitted.by_version_desc.first
                  else # everyone else only gets to see published or embargoed metadata latest version
                    id.latest_resource_with_public_metadata
                  end
    end

    helper_method :resource

    def resource_id
      resource.id
    end

    helper_method :resource_id

    # ############################################################
    # Actions

    def show
      response.set_header(
        'Link',
        "<#{linkset_url(id: resource.identifier_str)}>; rel=\"linkset\"; type=\"application/linkset\",
        <#{linkset_url(id: resource.identifier_str)}.json>; rel=\"linkset\"; type=\"application/linkset+json\""
      )
      @invitations = (params[:invitation] ? OrcidInvitation.where(secret: params[:invitation]).where(identifier_id: id.id) : nil)
      respond_to(&:html)
    end

    def citations
      @identifier = Identifier.find(params[:identifier_id])
      respond_to(&:js)
    end

    def metrics
      @identifier = Identifier.find(params[:identifier_id])
      respond_to(&:js)
    end

    def linkset
      respond_to do |format|
        format.html do
          response.set_header('Content-Type', 'application/linkset')
          render body: lset_linkset
        end
        format.json do
          response.set_header('Content-Type', 'application/linkset+json')
          render json: json_linkset
        end
      end
    end

    # ############################################################
    # Private

    private

    def require_identifier_and_resource
      # at least one of these will be nil when it doesn't exist or the user doesn't have permission
      render('not_available', status: 404) unless id && resource
    end

    def identifier_from(params)
      logger.error("Can't parse identifier from nil id param") && return unless params[:id].present?

      params.require(:id)
      id_param = params[:id].upcase
      type, id = id_param.split(':', 2)
      logger.error("Can't parse identifier from id_param '#{id_param}'") && return unless id

      identifiers = Identifier.where(identifier_type: type).where(identifier: id)
      logger.warn("Identifier '#{id}' not found (id_param was: '#{id_param}')") if identifiers.empty?

      identifiers.first
    end

    # rubocop:disable Metrics/MethodLength

    def lset_linkset
      anchor = show_url(id: resource.identifier_str)
      list = [
        {
          link: "https://doi.org/#{@id.identifier}",
          rel: 'cite-as'
        },
        {
          link: 'https://schema.org/Dataset',
          rel: 'type'
        },
        {
          link: 'https://schema.org/AboutPage',
          rel: 'type'
        },
        {
          link: resource.rights.first.rights_uri,
          rel: 'license'
        },
        {
          link: "https://doi.org/#{@id.identifier}",
          rel: 'describedby',
          type: 'application/vnd.datacite.datacite+json'
        }
      ]
      resource.authors.with_orcid.each do |a|
        list.push({
                    link: "https://orcid.org/#{a.author_orcid}",
                    rel: 'author'
                  })
      end
      resource.data_files.each do |f|
        list.push({
                    link: download_stream_url(file_id: f.id),
                    rel: 'item',
                    type: f.upload_content_type
                  })
        list.push({
                    link: show_url(id: resource.identifier_str),
                    rel: 'collection',
                    type: 'text/html',
                    anchor: download_stream_url(file_id: f.id)
                  })
        list.push({
                    link: 'https://schema.org/DataDownload',
                    rel: 'type',
                    anchor: download_stream_url(file_id: f.id)
                  })
      end

      map = list.map do |l|
        link = "<#{l[:link]}>; rel=\"#{l[:rel]}\""
        link += "; type=\"#{l[:type]}\"" if l[:type]&.present?
        link += "; anchor=\"#{l[:anchor]&.presence || anchor}\""
        link
      end
      map.join(',')
    end

    def json_linkset
      description = {
        anchor: show_url(id: resource.identifier_str),
        'cite-as': [
          { href: "https://doi.org/#{@id.identifier}" }
        ],
        type: [
          { href: 'https://schema.org/Dataset' },
          { href: 'https://schema.org/AboutPage' }
        ],
        license: [{ href: resource.rights.first.rights_uri }],
        describedby: [
          {
            href: "https://doi.org/#{@id.identifier}",
            type: 'application/vnd.datacite.datacite+json'
          }
        ]
      }
      description[:author] = resource.authors.with_orcid.map do |a|
        { href: "https://orcid.org/#{a.author_orcid}" }
      end
      description[:item] = resource.data_files.map do |f|
        {
          href: download_stream_url(file_id: f.id),
          type: f.upload_content_type
        }
      end
      collection = resource.data_files.map do |f|
        {
          anchor: download_stream_url(file_id: f.id),
          type: [{ href: 'https://schema.org/DataDownload' }],
          collection: [
            {
              href: show_url(id: resource.identifier_str),
              type: 'text/html'
            }
          ]
        }
      end
      {
        linkset: [
          description,
          collection
        ]
      }
    end
  end
  # rubocop:enable Metrics/MethodLength
end
