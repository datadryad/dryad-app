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

    def label_format(d)
      c = d.split('-')
      return Date.parse(d).strftime('%b %d, %Y') if d.length > 8
      return Date.new(c.first.to_i, c.last.to_i, 1).strftime('%b %Y') if d.length > 4

      d
    end

    # rubocop:disable Metrics/AbcSize
    def datasets_by_date
      sd = ActiveRecord::Base.connection.select_all(
        "select DATE_FORMAT(first_sub_date, '%Y-%m-%d') AS period, count(*) as count from (#{params[:sql]}) subquery GROUP BY period ORDER BY period"
      )
      pd = ActiveRecord::Base.connection.select_all(
        "select DATE_FORMAT(first_pub_date, '%Y-%m-%d') AS period, count(*) as count from (#{params[:sql]}) subquery GROUP BY period ORDER BY period"
      )
      subs = sd.to_a.reject { |h| h['period'].nil? }
      pubs = pd.to_a.reject { |h| h['period'].nil? }

      return [{ dates: [Date.today.strftime('%F')], subs: [0], pubs: [0] }] unless subs.first.present?

      range = (Date.parse(subs.first['period'])..Date.parse(subs.last['period'])).map { |d| d.strftime('%F') }.uniq

      if range.length > 30
        range = range.map { |d| d[0..6] }.uniq
        range = range.map { |d| d[0..3] }.uniq if range.length > 36
      end

      [{
        dates: range.map { |d| label_format(d) },
        subs: range.map { |d| subs.sum { |h| h['period'].start_with?(d) ? h['count'] : 0 } },
        pubs: range.map { |d| pubs.sum { |h| h['period'].start_with?(d) ? h['count'] : 0 } }
      }]
    end
    # rubocop:enable Metrics/AbcSize
  end
end
