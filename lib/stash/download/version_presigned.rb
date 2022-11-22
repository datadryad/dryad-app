require 'http'
require 'byebug'
require 'zaru'
require 'stash/download'

module Stash
  module Download

    class MerrittException < RuntimeError; end

    class VersionPresigned

      def initialize(resource:)
        @resource = resource
        return if @resource.blank?

        @tenant = resource&.tenant
        @version = @resource&.stash_version&.merritt_version
        # local_id is encoded, so later it gets double-encoded which is required by Merritt for some crazy reason
        _ignored, @local_id = @resource.merritt_protodomain_and_local_id
        @domain = @tenant&.repository&.domain

        @http = HTTP.use(normalize_uri: { normalizer: Stash::Download::NORMALIZER })
          .timeout(connect: 10, read: 10).timeout(10.seconds.to_i).follow(max_hops: 3)
          .basic_auth(user: @tenant&.repository&.username, pass: @tenant&.repository&.password)
      end

      def valid_resource?
        !(@resource.blank? || @tenant.blank? || @version.blank? || @domain.blank? || @local_id.blank?)
      end

      # this should return
      # 200 for URL being present to download
      # 202 for needing to wait with a progress bar
      # 404 for not found
      # 408 for timeout failures
      def download
        assemble_hash = {}
        assemble_hash = assemble if @resource.download_token.token.blank?
        return assemble_hash if [404, 408].include?(assemble_hash[:status]) # can't find or can't assemble right now

        status_hash = status

        return status_hash if [200, 408].include?(status_hash[:status]) # it's available or timing out, so return

        # if token not found or expired, then attempt to assemble it again
        if [404, 410].include?(status_hash[:status])
          assemble_hash = assemble

          # handle the object not able to assemble (not found or timing out)
          return assemble_hash if [404, 408].include?(assemble_hash[:status])

          status_hash = status # refresh status hash after assembling again
          return status_hash if status_hash[:status] == 408 # abort with more timeouts
        end

        # Merritt pads estimates 20+ seconds for stuff that can be assembled very quickly and started downloads within a few seconds
        return poll_and_download if @resource.download_token.availability_delay_seconds < 25

        status_hash
      rescue HTTP::TimeoutError
        { status: 408 }
      end

      # this does a limited poll and download if it becomes available within a reasonable time
      def poll_and_download(delay: 5, tries: 1)
        status_hash = {}
        # poll a couple of times to see if gets ready quickly and if not, return the last status
        1.upto(tries) do
          sleep delay
          status_hash = status
          break if status_hash[:status] == 200
        end
        status_hash # finally, return status hash whether download is ready or not
      end

      # resp.status.success?  # resp.status == 200
      # 200 is good and gives a token
      # {"status"=>200, "token"=>"11d2afdd-9351-4403-8013-88a9e9284e96", "cloud-content-byte"=>1228236,
      # "anticipated-availability-time"=>"2020-05-27T12:43:48-07:00", "message"=>"Request queued, use token to check status"}
      # Time.parse(json['anticipated-availability-time'])
      #
      # otherwise 404
      def assemble
        resp = @http.get(assemble_version_url)
        if resp.status.success?
          json = resp.parse.with_indifferent_access
          token = @resource.download_token
          token.token = json[:token]
          token.available = Time.parse(json['anticipated-availability-time'])
          token.save
          json
        else
          raise MerrittException, "status code: #{resp.status.code} from Merritt for #{assemble_version_url}\n#{resp.body}" if resp.status.code >= 500

          { status: resp.status.code, body: resp.body.to_s }
        end
      end

      # {"status"=>202, "token"=>"ed3b8dc1-afac-4487-bfac-fb89d654e4d9", "cloud-content-byte"=>1228236, "message"=>"Object is not ready"}
      # 200 -- ready
      # 202 -- not ready
      # 404 -- not found
      # 410 -- expired
      def status
        resp = @http.get(status_url)
        # sometimes Merritt returns non-JSON mimetypes so we don't want to parse them, maybe mostly for 404s?
        return { status: resp.status.code }.with_indifferent_access if resp.mime_type != 'application/json'

        resp.parse.with_indifferent_access
      end

      def assemble_version_url
        path = ::File.join('/api', 'assemble-version', ERB::Util.url_encode(@local_id), @version.to_s).to_s
        query = { format: 'zipunc', content: 'producer' }.to_query
        "#{@domain}#{path}?#{query}"
      end

      def status_url
        path = ::File.join('/api', 'presign-obj-by-token', ERB::Util.url_encode(@resource.download_token.token)).to_s
        query = { no_redirect: true, filename: filename }.to_query
        "#{@domain}#{path}?#{query}"
      end

      def filename
        fn = Zaru.sanitize!(@resource.identifier.to_s.gsub(%r{[:\\/]+}, '_'))
        fn.gsub!(/,|;|'|"|\u007F/, '')
        fn << "__v#{@version}"
        "#{fn}.zip"
      end
    end
  end
end
