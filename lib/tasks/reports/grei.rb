# :nocov:
module Tasks
  module Reports
    # rubocop:disable Metrics/ModuleLength
    module GREI
      class << self
        def generate_monthly_report
          template_path = Rails.root.join('public', 'pdf_templates', 'grei_monthly_report.html.erb')
          html_template = File.read(template_path)

          # Create an ERB template with the HTML
          erb_template = ERB.new(html_template)
          datasets = retrieve_datasets_info

          # Bind the data to the ERB template and render it
          rendered_html = erb_template.result_with_hash(
            month: Date.current.strftime('%B'),
            counts_data: datasets[:count],
            storage_data: datasets[:storage],
            graph_data: datasets[:graph_data],
            stats_data: datasets[:stats],
            counts_per_type: datasets[:dataset_counts_per_type],
            counts_per_license_type: datasets[:dataset_counts_per_license_type],
            citations_per_dataset: datasets[:citations_count_per_dataset]
          )

          pdf = Grover.new(rendered_html).to_pdf

          FileUtils.mkdir_p(REPORTS_DIR)
          outpath = File.join(REPORTS_DIR, "GREI_monthly_report_#{Time.now.strftime('%Y_%m_%d')}.pdf")
          File.open(outpath, 'wb') do |file|
            file << pdf
          end
        end

        private

        # rubocop:disable Metrics/MethodLength (this method is long but it's mostly data retrieval)
        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Layout/LineLength
        def retrieve_datasets_info
          monthly_counts = current_year_datasets
            .select("YEAR(#{resource_table_name}.created_at) AS year, MONTH(#{resource_table_name}.created_at) AS month, COUNT(DISTINCT #{resource_table_name}.id) AS total")
            .group("YEAR(#{resource_table_name}.created_at)", "MONTH(#{resource_table_name}.created_at)")
            .order("YEAR(#{resource_table_name}.created_at) DESC, MONTH(#{resource_table_name}.created_at) DESC")

          monthly_storage = current_year_datasets
            .select("YEAR(#{resource_table_name}.created_at) AS year, MONTH(#{resource_table_name}.created_at) AS month, SUM(#{resource_table_name}.total_file_size) AS total")
            .group("YEAR(#{resource_table_name}.created_at)", "MONTH(#{resource_table_name}.created_at)")
            .order("YEAR(#{resource_table_name}.created_at) DESC, MONTH(#{resource_table_name}.created_at) DESC")

          dataset_counts_per_type = current_month_datasets
            .joins(:identifier)
            .select("#{identifier_table_name}.identifier_type AS identifier_type, COUNT(DISTINCT #{identifier_table_name}.id) AS total")
            .group("#{identifier_table_name}.identifier_type")
            .order('total DESC')

          dataset_counts_per_license_type = current_month_datasets
            .joins(:identifier)
            .select("#{identifier_table_name}.license_id AS license_name, COUNT(DISTINCT  #{identifier_table_name}.id) AS total")
            .group("#{identifier_table_name}.license_id")
            .order('total DESC')

          citations_count_per_dataset = current_month_datasets
            .joins(identifier: :counter_stat)
            .select("COUNT(DISTINCT #{identifier_table_name}.id) AS identifiers_count, #{counter_stat_table_name}.citation_count AS total_citations")
            .group("#{counter_stat_table_name}.citation_count")
            .order('total_citations DESC')

          current_month_stats = calculate_stats(current_month_datasets)

          # TODO: calculating all-time averages on the fly is very expensive,
          #       we need to think about how to optimize this.
          all_time_average_stats = calculate_stats(current_year_datasets).tap do |stats|
            stats.transform_values! { |value| (value / current_year_datasets.count.to_f).round(2) }
          end

          {
            count: {
              new_datasets: current_month_datasets.count,
              total_datasets: base_datasets_scope.count
            },
            storage: {
              new_storage: (current_month_datasets.sum("#{StashEngine::Resource.table_name}.total_file_size").to_f / (1024**3)).round(2),
              total_storage: (base_datasets_scope.sum("#{StashEngine::Resource.table_name}.total_file_size").to_f / (1024**3)).round(2)
            },
            graph_data: {
              counts: monthly_counts,
              storage: monthly_storage
            },
            stats: {
              current_month: current_month_stats,
              all_time_average: all_time_average_stats
              # all_time_average: { views: '-', downloads: '-', citations: '-'}
            },
            dataset_counts_per_type: dataset_counts_per_type,
            dataset_counts_per_license_type: dataset_counts_per_license_type,
            citations_count_per_dataset: citations_count_per_dataset
          }
        end
        # rubocop:enable Metrics/MethodLength
        # rubocop:enable Metrics/AbcSize
        # rubocop:enable Layout/LineLength

        def nih_contributor_rors
          StashDatacite::ContributorGrouping
            .find_by(name_identifier_id: 'https://ror.org/01cwqze88')
            .json_contains
            .map do |associated_contributors|
              associated_contributors['name_identifier_id']
            end
        end

        def base_datasets_scope
          StashEngine::Resource
            .latest_per_dataset
            .joins(:contributors)
            .where("#{StashDatacite::Contributor.table_name}.contributor_type": 'funder')
            .where("#{StashDatacite::Contributor.table_name}.name_identifier_id": nih_contributor_rors)
            .distinct
        end

        def current_month_datasets
          base_datasets_scope.where("#{StashEngine::Resource.table_name}.created_at >= ?", 1.month.ago)
        end

        def current_year_datasets
          base_datasets_scope.where("#{StashEngine::Resource.table_name}.created_at >= ?", 1.year.ago)
        end

        def resource_table_name
          StashEngine::Resource.table_name
        end

        def identifier_table_name
          StashEngine::Identifier.table_name
        end

        def software_license_table_name
          StashEngine::SoftwareLicense.table_name
        end

        def counter_stat_table_name
          StashEngine::CounterStat.table_name
        end

        def calculate_stats(datasets)
          totals = { views: 0, downloads: 0, citations: 0 }

          # TODO: this needs to be optimized, ideally computed directly in SQL
          datasets.joins(identifier: :counter_stat).find_each do |resource|
            counter_stat = resource.identifier.counter_stat
            totals[:views] = totals[:views].to_i + counter_stat&.views.to_i
            totals[:downloads] = totals[:downloads].to_i + counter_stat&.downloads.to_i
            totals[:citations] = totals[:citations].to_i + counter_stat&.citation_count.to_i
          end

          totals
        end
      end
    end
    # rubocop:enable Metrics/ModuleLength
  end
end
# :nocov:
