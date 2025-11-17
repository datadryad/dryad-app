# frozen_string_literal: true

# This service provides tools for updating our local organizations from the Research Organization Registry (ROR)
# Initially adapted from the DMP Tool's RorService:
#   https://github.com/CDLUC3/dmptool/blob/v3.4.0-beta/app/services/external_apis/ror_service.rb

require 'digest'
require 'zip'

module Stash
  module Organization
    class RorUpdater

      FILE_DIR = '/home/ec2-user/deploy/shared/ror'
      DOWNLOAD_URL = 'https://zenodo.org/api/communities/ror-data/records?q=&sort=newest'

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
                dl_array = download_file.split('/')
                # Get v2 json file
                json_file = dl_array[dl_array.length - 2].gsub('.zip', '_schema_v2.json')

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
        def process_ror_json(json_file_path:)
          json_file = File.open(json_file_path, 'r')
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
        end

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
            Accept: 'application/json'
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
              process_ror_json(json_file_path: "#{FILE_DIR}/#{file}")
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
        # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        def process_ror_record(record)
          return nil unless record.present? && record.is_a?(Hash) && record['id'].present?

          acronyms = []
          aliases = []
          children = []
          record.fetch('names', []).each do |n|
            acronyms.push(n['value']) if n['types'].include?('acronym')
            aliases.push(n['value']) if n['types'].include?('alias')
            aliases.push(n['value']) if n['types'].include?('label') && !n['types'].include?('ror_display')
          end
          record.fetch('relationships', []).each do |rel|
            next unless rel['type'] == 'child'

            children.push({ contributor_name: rel['label'], identifier_type: 'ror', name_identifier_id: rel['id'] })
          end
          ror_display = record.fetch('names', []).find { |n| n['types'].include?('ror_display') } || {}
          website_link = record.fetch('links', []).find { |l| l['type'] == 'website' } || {}
          isni_ids = record.fetch('external_ids', []).find { |set| set['type'] == 'isni' } || {}

          ror_org = StashEngine::RorOrg.find_or_create_by(ror_id: record['id'])
          ror_org.name = safe_string(value: ror_display.fetch('value', ''))
          ror_org.home_page = safe_string(value: website_link.fetch('value', ''))
          ror_org.country = record.dig('locations', 0, 'geonames_details', 'country_name')
          ror_org.acronyms = acronyms
          ror_org.aliases = aliases
          ror_org.isni_ids = isni_ids.fetch('all', [])
          ror_org.status = record['status']
          ror_org.save

          if record['status'] == 'withdrawn'
            successor = record.fetch('relationships', []).select { |a| a['type'] == 'successor' }.first
            RorService.new(record['id']).withdrawn(successor) if successor.present?
          end

          unless children.empty?
            grouping = StashDatacite::ContributorGrouping.find_or_create_by(name_identifier_id: record['id'])
            grouping.contributor_name = ror_org.name
            grouping.identifier_type = 'ror'
            grouping.group_label = grouping.group_label.presence || 'Child institutions'
            grouping.json_contains = children
            grouping.save
          end
          true
        rescue StandardError => e
          puts('Error processing record', e)
          false
        end
        # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

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
