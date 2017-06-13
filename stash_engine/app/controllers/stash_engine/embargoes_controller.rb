require_dependency 'stash_engine/application_controller'

module StashEngine
  class EmbargoesController < ApplicationController
    before_action :set_embargo, only: [:delete]

    def messages
      @messages ||= []
    end
    helper_method :messages

    # GET /embargos/new
    def new
      @embargo = Embargo.new(resource_id: params[:resource_id])
    end

    # GET /embargos/1/edit
    def edit; end

    # POST /embargos
    def create
      @embargo = Embargo.new(embargo_params)
      respond_to do |format|
        if @embargo.save
          format.js
        else
          format.html { render :new }
        end
      end
    end

    # PATCH/PUT /embargos/1
    def update # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      @embargo = Embargo.where(resource_id: embargo_params[:resource_id]).first
      @resource = Resource.find(embargo_params[:resource_id])
      respond_to do |format|
        if embargo_params[:end_date].to_date == Date.today.to_date
          @embargo.destroy
          format.js { render 'delete' }
        else
          @embargo.update(embargo_params)
          format.js { render template: 'stash_datacite/shared/update.js.erb' }
        end
      end
    end

    # DELETE /embargos/1
    def delete
      @embargo.destroy
      respond_to do |format|
        format.js
      end
    end

    # this is a generic action to handle all create/modify/delete actions for an embargo since it's just one form
    # and using the rest methods in this case is overly complicated and annoying
    def changed # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      respond_to do |format|
        format.js do
          @resource = Resource.find(params[:resource_id])
          return unless @resource.user.id == current_user.id

          if params['when-to-publish'] == 'in_future'
            set_embargo_end_date(params['yyyyEmbargo'], params['mmEmbargo'], params['ddEmbargo'])
          elsif (@embargo = @resource.embargo)
            @embargo.destroy
          end
        end
      end
    end

    private

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
