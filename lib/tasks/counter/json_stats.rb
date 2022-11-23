require 'json'
require 'byebug'

# rubocop:disable Metrics/AbcSize
module Tasks
  module Counter
    class JsonStats

      def initialize
        # the tally hash is a simple structure like { '10.18737/D7MS44' => { investigation: 7, request: 2}, etc }
        # It keeps things in memory since constantly updating to the database for each addition for each month was slow
        # and once all files are done, then can update all the records in database at the end one time and speed this up a lot.
        @tally_hash = {}
      end

      def update_stats(filename)
        stats = JSON.parse(File.read(filename))
        datasets = stats['report-datasets']
        datasets.each_with_index do |ds, _idx|
          next if ds['dataset-id'].blank? || ds['dataset-id'].first.blank? || ds['dataset-id'].first['value'].blank? || ds['performance'].blank?

          doi = ds['dataset-id'].first['value']

          unique_request = 0
          unique_invest = 0

          ds['performance'].each do |perf|
            next if perf.blank? || perf['instance'].blank?

            perf['instance'].each do |instance|
              # make sure all this is valid before doing anything with it
              next if instance['access-method'].blank? || !%w[machine regular].include?(instance['access-method'])
              next if instance['metric-type'].blank? || !%w[unique-dataset-investigations unique-dataset-requests].include?(instance['metric-type'])
              next if instance['count'].blank? || !instance['count'].integer?

              case instance['metric-type']
              when 'unique-dataset-investigations'
                unique_invest += instance['count']
              when 'unique-dataset-requests'
                unique_request += instance['count']
              end
            end
          end

          update_hash(doi: doi, request: unique_request, invest: unique_invest)
        end
      end

      def update_hash(doi:, request:, invest:)
        doi.strip!
        doi.downcase!

        @tally_hash[doi] = { investigation: 0, request: 0 } unless @tally_hash.key?(doi)

        @tally_hash[doi][:investigation] += invest
        @tally_hash[doi][:request] += request
      end

      # does all updates to the database from the tally hash at once when called.
      def update_database
        @tally_hash.each_pair do |k, v|
          doi_obj = StashEngine::Identifier.find_by_identifier(k)
          next if doi_obj.nil?

          stat = doi_obj.counter_stat
          stat.unique_investigation_count = v[:investigation]
          stat.unique_request_count = v[:request]
          # these are needed to keep the citations rolling
          stat.created_at = Time.new - 48.hours
          stat.updated_at = Time.new - 48.hours
          stat.save
          puts "Updated database for #{k} -- investigation: #{v[:investigation]}, request: #{v[:request]}"
        end
      end
    end
  end
end
# rubocop:enable Metrics/AbcSize
