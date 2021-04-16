require 'http'
require 'byebug'
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
          file.merritt_s3_presigned_url
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

    def output_csv(filename:)
      CSV.open(filename, 'w') do |writer|
        writer << @accumulator.first.keys
        @accumulator.each { |i| writer << i.values }
      end
    end
  end
end
