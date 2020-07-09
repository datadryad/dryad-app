require 'json'
require 'byebug'

# rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
class JsonStats

  def initialize(filename)
    @stats = JSON.parse(File.read(filename))
  end

  def update_stats
    datasets = @stats['report-datasets']
    datasets.each_with_index do |ds, idx|
      puts "  #{idx}/#{datasets.length} processed" if idx % 100 == 0

      next if ds['dataset-id'].blank? || ds['dataset-id'].first.blank? || ds['dataset-id'].first['value'].blank? || ds['performance'].blank?

      doi = ds['dataset-id'].first['value']

      unique_request = 0
      unique_invest = 0

      ds['performance'].each do |perf|
        next if perf.blank? || perf['instance'].blank?

        perf['instance'].each do |instance|
          # make sure all this crap is valid before doing anything with it
          next if instance['access-method'].blank? || !%w[machine regular].include?(instance['access-method'])
          next if instance['metric-type'].blank? || !%w[unique-dataset-investigations unique-dataset-requests].include?(instance['metric-type'])
          next if instance['count'].blank? || !instance['count'].integer?

          if instance['metric-type'] == 'unique-dataset-investigations'
            unique_invest += instance['count']
          elsif instance['metric-type'] == 'unique-dataset-requests'
            unique_request += instance['count']
          end
        end
      end

      # puts "#{doi} request: #{unique_request}  invest: #{unique_invest}"
      update_database(doi: doi, request: unique_request, invest: unique_invest)
    end
  end

  def update_database(doi:, request:, invest:)
    doi.strip!
    doi_obj = StashEngine::Identifier.find_by_identifier(doi)
    return if doi_obj.nil?

    stat = doi_obj.counter_stat
    stat.unique_investigation_count += invest
    stat.unique_request_count += request
    # these are needed to keep the citations rolling
    stat.created_at = Time.new - 48.hours
    stat.updated_at = Time.new - 48.hours
    stat.save
  end
end

# rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
