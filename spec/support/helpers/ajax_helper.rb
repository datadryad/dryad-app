module AjaxHelper

  def wait_for_ajax(seconds = Capybara.default_max_wait_time)
    Timeout.timeout(seconds) do
      loop until finished_all_ajax_requests?
    end
  end

  def finished_all_ajax_requests?
    page.evaluate_script('jQuery.active').zero?
  end

end

RSpec.configure do |config|
  config.include(AjaxHelper, type: :system)
end
