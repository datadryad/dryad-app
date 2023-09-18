require 'http'
require 'byebug'
require 'cgi'

module Tasks
  module DownloadCheck
    class Merritt

      def initialize(identifiers:)
        @identifiers = identifiers
      end

      def check_a_download
        @accumulator = []
        @identifiers.each_with_index do |identifier, idx|
          res = identifier.latest_resource_with_public_metadata
          puts "#{idx + 1}/#{@identifiers.count} checking #{identifier.identifier}, resource: #{res.id}"
          file = res.data_files.present_files.first
          next if file.nil?

          begin
            file.s3_permanent_presigned_url
            @accumulator.push(
              { doi: identifier.identifier, resource: res.id, file: file.upload_file_name,
                dl_uri: res.download_uri, error: false }
            )
          rescue Stash::Download::MerrittError, HTTP::Error => e
            @accumulator.push(
              { doi: identifier.identifier, resource: res.id, file: file.upload_file_name,
                dl_uri: res.download_uri, error: e.to_s }
            )
          end
          sleep 0.5
        end
      end

      def check_all_files
        # we always have to do this because the normalizer in 'http.rb' randomly mangles some things
        @http = HTTP.use(normalize_uri: { normalizer: Stash::Download::NORMALIZER })
        @accumulator = []
        last_query_time = Time.new

        @identifiers.each_with_index do |identifier, idx|
          res = identifier.latest_resource_with_public_metadata
          puts "#{idx + 1}/#{@identifiers.count} checking #{identifier.identifier}, resource: #{res.id}"
          res.data_files.present_files.each do |file|
            if file.nil? || res.download_uri.blank?
              save_error(resource: res, file: file, error: 'file or download_url blank')
              next
            end

            begin
              # get presigned url
              # give at least some time between requests if it doesn't take that long to run so we don't hammer Merritt to death
              sleep 0.01 while Time.new - last_query_time < 0.05
              last_query_time = Time.new

              url = file.s3_permanent_presigned_url

              resp = @http.get(url)
              size = resp.headers['Content-Length']&.to_i || 0

              if resp.status.code >= 400
                save_error(resource: res, file: file, error: "http status response from S3: #{resp.status.code}")
                next
              end

              if file.upload_file_size != size
                save_error(resource: res, file: file, error: "bad content length: db: #{file.upload_file_size} vs s3: #{size}")
              end
            rescue Stash::Download::MerrittError, HTTP::Error => e
              save_error(resource: res, file: file, error: e)
            end
          end
        end
      end
      # rubocop:enable

      def save_error(resource:, file:, error:)
        ark = %r{/d/(.+)$}.match(resource.download_uri)
        ark = (ark.nil? ? 'unknown' : ark[1])
        puts "  Found error in file #{file&.upload_file_name}"
        @accumulator.push(
          { doi: resource.identifier.identifier, resource: resource.id, file: file&.upload_file_name,
            merritt_version: resource&.stash_version&.merritt_version, ark: CGI.unescape(ark),
            error: error.to_s }
        )
      end

      def output_csv(filename:)
        CSV.open(filename, 'w') do |writer|
          writer << @accumulator.first.keys unless @accumulator.empty?
          @accumulator.each { |i| writer << i.values }
        end
      end
    end
  end
end
