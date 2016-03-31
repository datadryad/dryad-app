require_dependency 'stash_datacite/application_controller'

module StashDatacite
  # this is a class for composite (AJAX/UJS?) views starting at the resource or resources
  class ResourcesController < ApplicationController
    before_action :ajax_require_current_user, only: [:user_in_progress]
    before_action :set_page_info

    # get resources and composite information for in-progress table view
    def user_in_progress
      respond_to do |format|
        format.js {
          #paging first and using separate object for pager (resources) from display (@in_progress_lines) means
          #only a page of objects needs calculations for display rather than all objects in list.  However if we need
          #to sort on calculated fields for display we'll need to calculate all values, sort and use the array pager
          #form of kaminari instead (which will likely be slower).
          @resources = StashDatacite.resource_class.where(user_id: session[:user_id]).page(@page).per(@page_size)
          @in_progress_lines = @resources.map { |resource| DatasetPresenter.new(resource) }
        }
      end
    end

    def show
      respond_to do |format|
        format.js {
          @resource = StashDatacite.resource_class.find(params[:id])
          @data = check_required_fields(@resource)
          @review = Resource::Review.new(@resource)
        }
      end
    end

    # Review responds as a get request to review the resource before saving
    def review
      respond_to do |format|
        format.js {
          @resource = StashDatacite.resource_class.find(params[:id])
          @data = check_required_fields(@resource)
          @review = Resource::Review.new(@resource)
        }
      end
    end

    def submission
      resource = StashDatacite.resource_class.find(params[:resource_id])
      @resource_file_generation = Resource::ResourceFileGeneration.new(resource, current_tenant)
      @resource_file_generation.generate_xml
    end

    private

    def check_required_fields(resource)
      @completions = Resource::Completions.new(resource)
      # required fields are Title, Institution, Data type, Data Creator(s), Abstract
      unless @completions.required_completed == @completions.required_total
        data = []
        data << "Title" unless @completions.title
        data << "Resource Type" unless @completions.data_type
        data << "Abstract" unless @completions.abstract
        data << "Author" unless @completions.creator
        data << "Affliation" unless @completions.institution
        return data.join(', ')
      end
    end

    def create_resource_state(state, resource)
      unless resource.current_resource_state.to_sym == state
        resource.save!
        StashEngine::ResourceState.create!(resource_id: resource.id, resource_state: :submitted, user_id: current_user.id )
        redirect_to stash_url_helpers.dashboard_path, notice: "#{resource.titles.first.title} submitted with doi:XXXXXXXXXX. There may be a delay for processing before the item is available."
      else
        redirect_to stash_url_helpers.dashboard_path, alert: 'The dataset has already been submitted.'
      end
    end

    # def flash_error_missing_data(completions)
    #   data = []
    #   data << "Title" unless completions.title
    #   data << "Resource Type" unless completions.data_type
    #   data << "Abstract" unless completions.abstract
    #   data << "Author" unless completions.creator
    #   data << "Affliation" unless completions.institution
    #   return data.join(', ')
    # end
  end
end

