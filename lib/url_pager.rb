# frozen_string_literal: true

class UrlPager

  def initialize(current_url:, result_count:, current_page:, page_size:, path_only: true)
    @current_url_str = current_url
    @result_count = result_count
    @current_page = current_page
    @page_size = page_size
    @path_only = path_only
    @current_uri = URI.parse(current_url)
    @current_uri.fragment = nil
    @qs_hash = Rack::Utils.parse_nested_query(@current_uri.query)
    @qs_hash.delete('page')
  end

  def paging_hash
    hsh = {
      self: self_url,
      first: first_url,
      last: last_url,
      prev: prev_url,
      next: next_url
    }.compact
    hsh.to_h { |k, v| [k, { href: v }] }
  end

  def self_url
    uri_output(URI.parse(@current_url_str))
  end

  def first_url
    make_url(page: nil)
  end

  def last_url
    make_url(page: last_page.to_s)
  end

  def prev_url
    return nil if @current_page < 2

    make_url(page: @current_page - 1)
  end

  def next_url
    return nil if @current_page >= last_page

    make_url(page: @current_page + 1)
  end

  private

  def last_page
    ((@result_count - 1) / @page_size) + 1
  end

  def make_querystring(hsh)
    return nil if hsh.compact.empty?

    hsh.compact.to_query
  end

  def make_url(page:)
    bu = @current_uri.clone
    bu.query = make_querystring(@qs_hash.merge(page: page))
    uri_output(bu)
  end

  # takes a URI
  def uri_output(u)
    if @path_only
      "#{u.path}#{u.query ? "?#{u.query}" : ''}"
    else
      u.to_s
    end
  end
end
