require 'date'

module StashEngine
  module AdminChartsHelper
    def size_chart
      tiers = FeeCalculator::InstitutionService.new.storage_fee_tiers
      query = tiers.map do |t|
        "SUM(CASE WHEN total_file_size BETWEEN #{t[:range].to_s.split('..').map(&:to_i).join(' AND ')} THEN 1 ELSE 0 END) as tier#{t[:tier]}"
      end.join(', ')
      ActiveRecord::Base.connection.select_all(
        "select #{query} from (#{params[:sql]}) subquery"
      ).to_a
    end

    # rubocop:disable Layout/LineLength, Metrics/AbcSize
    def datasets_monthly
      sd = ActiveRecord::Base.connection.select_all(
        "select CONCAT(YEAR(submit_date), ' ', QUARTER(submit_date)) AS period, count(*) as count from (#{params[:sql]}) subquery GROUP BY period ORDER BY period"
      )
      pd = ActiveRecord::Base.connection.select_all(
        "select CONCAT(YEAR(first_pub_date), ' ', QUARTER(first_pub_date)) AS period, count(*) as count from (#{params[:sql]}) subquery GROUP BY period ORDER BY period"
      )
      subs = sd.to_a.reject { |h| h['period'].nil? }
      pubs = pd.to_a.reject { |h| h['period'].nil? }

      return [{ dates: ["#{seasons[Date.today.quarter.to_i]} #{Date.today.year}"], subs: [0], pubs: [0] }] unless subs.first.present?

      f = subs.first['period'].split
      l = subs.last['period'].split
      qs = { 1 => 1, 2 => 4, 3 => 7, 4 => 10 }
      seasons = { 1 => 'Winter', 2 => 'Spring', 3 => 'Summer', 4 => 'Autumn' }

      range = (Date.new(f.first.to_i, qs[f.last.to_i], 1)..Date.new(l.first.to_i, qs[l.last.to_i], 1)).map { |d| "#{d.year} #{d.quarter}" }.uniq
      [{
        dates: range.map { |d| "#{seasons[d.split.last.to_i]} #{d.split.first}" },
        subs: range.map { |d| subs.find { |h| h['period'] == d }&.[]('count') || 0 },
        pubs: range.map { |d| pubs.find { |h| h['period'] == d }&.[]('count') || 0 }
      }]
    end
    # rubocop:enable Layout/LineLength, Metrics/AbcSize
  end
end
