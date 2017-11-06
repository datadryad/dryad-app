require_dependency 'stash_engine/application_controller'

module StashEngine
  class EmbargoesController < ApplicationController

    before_action :ajax_require_modifiable, only: %i[changed]

    def messages
      @messages ||= []
    end
    helper_method :messages

    # this is a generic action to handle all create/modify/delete actions for an embargo since it's just one form
    # and using the rest methods in this case is overly complicated and annoying
    def changed
      respond_to do |format|
        format.js do
          if params['when-to-publish'] == 'in_future'
            set_embargo_end_date(params['yyyyEmbargo'], params['mmEmbargo'], params['ddEmbargo'])
          elsif (@embargo = @resource.embargo)
            @embargo.destroy
          end
        end
      end
    end

    private

    def resource
      @resource ||= Resource.find(params[:resource_id])
    end

    def set_embargo_end_date(year, month, day)
      end_time = parse(year, month, day)
      return unless end_time
      @embargo = Embargo.find_or_create_by(resource_id: @resource.id)
      @embargo.end_date = end_time
      @embargo.save
    end

    def parse(year, month, day)
      if can_parse(year, month, day)
        end_time = try_parse(year, month, day)
        return end_time if end_time_in_range?(end_time)
        messages << "Please enter a date between now and #{max_end_time.strftime('%-m/%-d/%Y')}."
      else
        messages << 'Please enter numeric values for the month / day / year.'
      end
      nil
    end

    def try_parse(year, month, day)
      Time.new(year.to_i, month.to_i, day.to_i)
    rescue ArgumentError
      messages << 'Please enter a valid month / day / year for your date.'
      nil
    end

    def can_parse(year, month, day)
      [year, month, day].all? { |p| p.match(Regexp.new(/^\d+$/)) }
    end

    def end_time_in_range?(end_date)
      (end_date >= today_time) && (end_date < max_end_time)
    end

    def max_end_time
      @max_end_time ||= today_time + APP_CONFIG.max_review_days.to_i.days
    end

    def today_time
      @today ||= Date.today.to_time
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_embargo
      @embargo = Embargo.find(embargo_params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def embargo_params
      params.require(:embargo).permit(:id, :end_date, :resource_id)
    end

  end
end
