require_dependency 'stash_engine/application_controller'

module StashEngine
  class EmbargoesController < ApplicationController
    before_action :set_embargo, only: [:delete]

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
    def update
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
    def changed
      respond_to do |format|
        format.js do
          @resource = Resource.find(params[:resource_id])
          @embargo = @resource.embargo
          @messages = []
          return if @resource.user.id != current_user.id
          if params['when-to-publish'] == 'in_future'
            @embargo = Embargo.new(resource_id: @resource.id) unless @embargo
            r = Regexp.new(/^\d+$/)
            # all numbers
            if params['mmEmbargo'].match(r) && params['ddEmbargo'].match(r) && params['yyyyEmbargo'].match(r)
              mm = params['mmEmbargo'].to_i
              dd = params['ddEmbargo'].to_i
              yyyy = params['yyyyEmbargo'].to_i
              if !valid_date_parts?(yyyy, mm, dd)
                @messages += ['Please enter a valid month / day / year for your date.']
              elsif !valid_range?(yyyy, mm, dd)
                @messages += ['Please enter a date between now and ' \
                      "#{(Time.new + APP_CONFIG.max_review_days.to_i.days).strftime('%-m/%-d/%Y')}."]
              else
                @embargo.end_date = Time.new(yyyy, mm, dd)
                @embargo.save
              end
            else
              @messages += ['Please enter numeric values for the month / day / year.']
            end
          else
            # publish now, not later.  Destroy embargo
            @embargo.destroy if @embargo
          end
        end
      end
    end

    private

    def valid_date_parts?(yyyy, mm, dd)
      begin
        Time.new(yyyy, mm, dd)
      rescue ArgumentError => ex
        return false
      end
      true
    end

    def valid_range?(yyyy, mm, dd)
      t = Time.new
      today = Time.new(t.year, t.month, t.day)
      max_day = Time.new + APP_CONFIG.max_review_days.to_i.days
      my_day = Time.new(yyyy, mm, dd)
      (my_day >= today) && (my_day < max_day)
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
