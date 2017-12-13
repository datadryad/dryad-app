require 'url_pager'

module StashApi
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception

    PAGE_SIZE = 10

    UNACCEPTABLE_MSG = '406 - unacceptable: please set your Content-Type and Accept headers for application/json'

    def page
      @page ||= ( params[:page].to_i > 0 ? params[:page].to_i : 1)
    end

    def page_size
      PAGE_SIZE
    end

    def paging_hash(result_count:)
      up = UrlPager.new(current_url: request.original_url, result_count: result_count, current_page: page, page_size: page_size)
      up.paging_hash
    end

  end
end
