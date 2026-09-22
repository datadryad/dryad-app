class ChartsController < StashEngine::ApplicationController
  before_action :require_user_login, except: :metrics_chart

  # rubocop:disable Metrics/AbcSize
  def metrics_chart
    metrics = Datacite::Metadata.new(doi: params[:doi]).metrics
    views = metrics[:views]
    downloads = metrics[:downloads]
    citations = metrics[:citations]
    respond_to do |format|
      format.js do
        return @metrics = { dates: [Date.today.strftime('%Y')], views: [], downloads: [], citations: [] } unless metrics.dig(:views, 0).present?

        range = (Date.parse("#{metrics[:views].first['yearMonth']}-01")..Date.today).map { |d| d.strftime('%Y-%m') }.uniq.reject(&:blank?)

        if range.length > 36
          range = range.map { |d| d[0..3] }.uniq
          views = group_metric(views)
          downloads = group_metric(downloads)
        end

        @metrics = {
          dates: range.map { |d| label_format(d) },
          views: views.map { |m| { x: label_format(range.reverse.find { |d| d.start_with?(m['yearMonth']) }), y: m['total'] } },
          downloads: downloads.map { |m| { x: label_format(range.reverse.find { |d| d.start_with?(m['yearMonth']) }), y: m['total'] } },
          citations: citations.reject { |m| m['year'] == '0000' }.map do |m|
            { x: label_format(range.reverse.find do |d|
              d.start_with?(m['year'])
            end), y: m['total'] }
          end
        }
      end
    end
  end
  # rubocop:enable Metrics/AbcSize

  def size_chart
    tiers = FeeCalculator::InstitutionService.new.storage_fee_tiers
    query = tiers.map do |t|
      "SUM(CASE WHEN total_file_size BETWEEN #{t[:range].to_s.split('..').map(&:to_i).join(' AND ')} THEN 1 ELSE 0 END) as tier#{t[:tier]}"
    end.join(', ')
    data = ActiveRecord::Base.connection.select_all(
      "select #{query} from (#{params[:sql]}) subquery"
    )
    @data = JSON.parse(data.first.to_json, symbolize_names: true)
    respond_to(&:js)
  end

  def status_chart
    query = [
      "SUM(CASE WHEN pub_state in ('published', 'embargoed', 'retracted') THEN 1 ELSE 0 END) as published",
      "SUM(CASE WHEN pub_state = 'unpublished' and status in ('peer_review', 'to_be_published') THEN 1 ELSE 0 END) as kept_private",
      "SUM(CASE WHEN pub_state = 'unpublished' and status in ('queued', 'curation') THEN 1 ELSE 0 END) as curation",
      "SUM(CASE WHEN pub_state = 'unpublished' and status in ('in_progress', 'action_required') THEN 1 ELSE 0 END) as edits_needed",
      "SUM(CASE WHEN pub_state = 'withdrawn' THEN 1 ELSE 0 END) as withdrawn"
    ]
    data = ActiveRecord::Base.connection.select_all(
      "select #{query.join(', ')} from (#{params[:sql]}) subquery"
    )
    @data = JSON.parse(data.first.to_json, symbolize_names: true)
    respond_to(&:js)
  end

  def datasets_by_date
    return [{ dates: [Date.today.strftime('%F')], subs: [0], qs: [0], pubs: [0] }] if submission_query.first.blank? || publication_query.first.blank?

    range = date_range
    data = {
      dates: range.map { |d| label_format(d) },
      subs: range.map { |d| submission_query.sum { |h| h['period'].start_with?(d) ? h['count'] : 0 } },
      qs: range.map { |d| queue_query.sum { |h| h['period'].start_with?(d) ? h['count'] : 0 } },
      pubs: range.map { |d| publication_query.sum { |h| h['period'].start_with?(d) ? h['count'] : 0 } }
    }
    @data = JSON.parse(data.to_json, symbolize_names: true)
    respond_to(&:js)
  end

  private

  def label_format(d)
    c = d.split('-')
    return Date.parse(d).strftime('%b %d, %Y') if d.length > 8
    return Date.new(c.first.to_i, c.last.to_i, 1).strftime('%b %Y') if d.length > 4

    d
  end

  def group_metric(metric)
    h = metric.group_by { |m| m['yearMonth'][0..3] }
    h.map { |k, v| { 'yearMonth' => k, 'total' => v.sum { |m| m['total'] } } }
  end

  def submission_query
    return @subs if @subs

    sd = ActiveRecord::Base.connection.select_all(
      "select DATE_FORMAT(first_sub_date, '%Y-%m-%d') AS period, count(*) as count from (#{params[:sql]}) subquery GROUP BY period ORDER BY period"
    )
    @subs = sd.to_a.reject { |h| h['period'].nil? }
  end

  def queue_query
    return @queue_date_query if @queue_date_query

    qd = ActiveRecord::Base.connection.select_all(
      "select DATE_FORMAT(queue_date, '%Y-%m-%d') AS period, count(*) as count from (#{params[:sql]}) subquery GROUP BY period ORDER BY period"
    )
    @queue_date_query = qd.to_a.reject { |h| h['period'].nil? }
  end

  def publication_query
    return @publication_date_query if @publication_date_query

    pd = ActiveRecord::Base.connection.select_all(
      "select DATE_FORMAT(first_pub_date, '%Y-%m-%d') AS period, count(*) as count from (#{params[:sql]}) subquery GROUP BY period ORDER BY period"
    )
    @publication_date_query = pd.to_a.reject { |h| h['period'].nil? }
  end

  def date_range
    range = (Date.parse(submission_query.first['period'])..Date.parse(publication_query.last['period'])).map { |d| d.strftime('%F') }.uniq
    if range.length > 62
      range = range.map { |d| d[0..6] }.uniq
      range = range.map { |d| d[0..3] }.uniq if range.length > 36
    end
    range
  end
end
