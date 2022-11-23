# frozen_string_literal: true

# This service provides tools for updating our local organizations from the Research Organization Registry (ROR)
# Initially adapted from the DMP Tool's RorService:
#   https://github.com/CDLUC3/dmptool/blob/v3.4.0-beta/app/services/external_apis/ror_service.rb

require 'digest'
require 'zip'

module Stash
  module Organization
    class RorUpdater

      FILE_DIR = '/apps/dryad/apps/ui/shared/ror'
      DOWNLOAD_URL = 'https://zenodo.org/api/records/?communities=ror-data&sort=mostrecent'

      # rubocop:disable Metrics/MethodLength, Metrics/BlockNesting
      def self.perform(force: false)
        checksum_file = File.join(FILE_DIR, 'ror_checksum.txt')
        zip_file = File.join(FILE_DIR, 'latest-ror-data.zip')

        # Fetch the Zenodo metadata for ROR to see if we have the latest data dump
        metadata = fetch_zenodo_metadata

        if metadata.present?
          FileUtils.mkdir_p(FILE_DIR)

          checksum = File.open(checksum_file, 'w+') unless File.exist?(checksum_file) && !force
          checksum = File.open(checksum_file, 'r+') unless checksum.present?
          old_checksum_val = checksum.read

          if old_checksum_val == metadata['checksum']
            puts('There is no new ROR file to process.')
          else
            download_file = metadata['links']['self']
            puts("New ROR file detected - checksum #{metadata['checksum']}")
            puts("Downloading #{download_file}")

            payload = download_ror_file(download_file)

            if payload.present?
              file = File.open(zip_file, 'wb')
              file.write(payload)

              if validate_downloaded_file(file_path: zip_file, checksum: metadata['checksum'])
                # Hopefully, parse the correct filename out...though ROR hasn't been consistent with their names
                json_file = download_file.split('/').last.gsub('.zip', '.json').gsub('.json.json', '.json')

                # Process the ROR JSON
                if process_ror_file(zip_file: zip_file, file: json_file)
                  checksum = File.open(checksum_file, 'w')
                  checksum.write(metadata['checksum'])
                end
              else
                puts('Downloaded ROR zip does not match checksum!')
              end

            else
              puts('Unable to download ROR file!')
            end
          end
        else
          puts('Unable to fetch ROR metadata from Zenodo!')
        end
      end
      # rubocop:enable Metrics/MethodLength, Metrics/BlockNesting

      class << self
        private

        # Fetch the latest Zenodo metadata for ROR files
        def fetch_zenodo_metadata
          # Fetch the latest ROR metadata from Zenodo (the query will place the most recent
          # version 1st)
          resp = HTTParty.get(DOWNLOAD_URL, headers: { host: 'zenodo.org' })
          unless resp.present? && resp.code == 200
            puts("Unable to fetch ROR metadata from Zenodo #{resp}")
            return nil
          end
          resp_hash = resp.parsed_response

          # Extract the most recent file's metadata
          file_metadata = resp_hash['hits']['hits'].first['files'].first
          unless file_metadata.present? && file_metadata['links']['self'].present?
            puts('No file found in ROR metadata from Zenodo')
            return nil
          end

          file_metadata
        end

        # Download the latest ROR data
        def download_ror_file(url)
          return nil unless url.present?

          puts 'Downloading ROR data file...'

          headers = {
            host: 'zenodo.org',
            Accept: 'application/zip'
          }
          resp = HTTParty.get(url, headers: headers)
          unless resp.present? && resp.code == 200
            puts("Unable to fetch ROR file from Zenodo -- #{url} -- #{resp}")
            return nil
          end
          resp.parsed_response
        end

        # Determine if the downloaded file matches the expected checksum
        def validate_downloaded_file(file_path:, checksum:)
          return false unless file_path.present? && checksum.present? && File.exist?(file_path)

          puts 'Validating file against expected checksum...'

          checksum = checksum[4..] if checksum.starts_with?('md5:')

          actual_checksum = Digest::MD5.file(file_path).to_s
          actual_checksum == checksum
        end

        # Parse the JSON file and process each individual record
        def process_ror_file(zip_file:, file:)
          puts 'Processing file contents into database...'
          return false unless zip_file.present? && file.present?

          if unzip_file(zip_file: zip_file, destination: FILE_DIR)
            if File.exist?("#{FILE_DIR}/#{file}")
              json_file = File.open("#{FILE_DIR}/#{file}", 'r')
              json = JSON.parse(json_file.read)
              cntr = 0
              total = json.length
              json.each do |hash|
                cntr += 1
                puts "Processed #{cntr} out of #{total} records" if (cntr % 1000).zero?

                hash = hash.with_indifferent_access if hash.is_a?(Hash)

                next if process_ror_record(hash)

                puts("Unable to process record for: '#{hash&.fetch('name', 'unknown')}'")
              end
              true
            else
              puts('Unable to find json in zip!')
              false
            end
          else
            puts('Unable to unzip contents of ROR file')
            false
          end
        rescue JSON::ParserError => e
          puts(e)
          false
        end

        def unzip_file(zip_file:, destination:)
          return false unless zip_file.present? && File.exist?(zip_file)

          Zip::File.open(zip_file) do |files|
            files.each do |entry|
              next if File.exist?(entry.name)

              f_path = File.join(destination, entry.name)
              FileUtils.mkdir_p(File.dirname(f_path))
              files.extract(entry, f_path) unless File.exist?(f_path)
            end
          end
          true
        end

        # Transfer the contents of a single JSON record to the database
        def process_ror_record(record)
          return nil unless record.present? && record.is_a?(Hash) && record['id'].present?

          ror_org = StashEngine::RorOrg.find_or_create_by(ror_id: record['id'])
          ror_org.name = safe_string(value: record['name'])
          ror_org.home_page = safe_string(value: record.fetch('links', []).first)
          ror_org.country = record.dig('country', 'country_name')
          ror_org.acronyms = record['acronyms']
          ror_org.aliases = record['aliases']
          ror_org.isni_ids = record.dig('external_ids', 'ISNI', 'all')
          ror_org.save
          true
        rescue StandardError => e
          puts('Error processing record', e)
          false
        end

        def safe_string(value:)
          return value if value.blank? || value.length < 190

          value[0..190]
        end

        # Extracts the website domain from the item
        def org_website(item:)
          return nil unless item.present? && item.fetch('links', [])&.any?
          return nil if item['links'].first.blank?

          # A website was found, so extract just the domain without the www
          domain_regex = %r{^(?:http://|www\.|https://)([^/]+)}
          website = item['links'].first.scan(domain_regex).last.first
          website.gsub('www.', '')
        end

      end
    end
  end
end
