require 'http'
require 'byebug'
require 'zaru'

module Stash
  module Download
    class VersionPresigned
      attr_accessor :token

      def initialize(resource:)
        @resource = resource
        @tenant = resource&.tenant
        @version = @resource&.stash_version&.merritt_version
        # local_id is encoded, so later it gets double-encoded which is required by Merritt for some crazy reason
        _ignored, @local_id = @resource.merritt_protodomain_and_local_id
        @domain = @tenant.repository.domain

        @http = HTTP.timeout(connect: 30, read: 30).timeout(1.hour.to_i).follow(max_hops: 10)
                    .basic_auth(user: @tenant&.repository&.username, pass: @tenant&.repository&.password)
      end

      def valid_resource?
        !(@resource.blank? || @tenant.blank? || @version.blank? || @domain.blank? || @local_id.blank?)
      end

      # this should return
      # 200 for URL being present to download
      # 202 for needing to wait with a progress bar
      # 404 for not found
      def download
        assemble_hash = {}
        assemble_hash = assemble if @resource.download_token.token.blank?
        return { status: 404 } if assemble_hash[:status] == 404

        status_hash = status

        return status_hash if status_hash[:status] == 200 # it's here, do a download

        if [404, 410].include?(status_hash[:status]) # not found or expired, then assemble it again
          assemble
        end

        ready_time = @resource.download_token.available - Time.new

        if ready_time.positive? && ready_time < 30.seconds
          poll_and_download
        else
          status
        end
      end

      def poll_and_download
        puts "\n\nPOLLING FOR DOWNLOAD\n\n"
        status_hash = {}
        1.upto(2) do
          sleep 7
          status_hash = status
          break if status_hash[:status] == 200
        end
        status_hash
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
        end
        json
      end

      # {"status"=>202, "token"=>"ed3b8dc1-afac-4487-bfac-fb89d654e4d9", "cloud-content-byte"=>1228236, "message"=>"Object is not ready"}
      # 200 -- ready
      # 202 -- not ready
      # 404 -- not found
      # 410 -- expired
      def status
        resp = @http.get(status_url)
        resp.parse.with_indifferent_access
      end

      def assemble_version_url
        URI::HTTPS.build(
            host: @domain,
            path: File.join('/api', 'assemble-version', ERB::Util.url_encode(@local_id), @version.to_s),
            query: {format: 'zip', content: 'producer'}.to_query).to_s
      end

      def status_url
        URI::HTTPS.build(
          host: @domain,
          path: File.join('/api', 'presign-obj-by-token', ERB::Util.url_encode(@resource.download_token.token)),
          query: {no_redirect: true, filename: filename}.to_query).to_s
      end

      def filename
        fn = Zaru.sanitize!(@resource.identifier.to_s.gsub(%r{[\:\\/]+}, '_'))
        fn.gsub!(/,|;|'|"|\u007F/, '')
        fn << "__v#{@version}"
        "#{fn}.zip"
      end
    end
  end
end
