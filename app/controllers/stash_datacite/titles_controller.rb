module StashDatacite
  class TitlesController < ApplicationController

    before_action :ajax_require_modifiable, only: [:update]

    respond_to :json

    # PATCH/PUT /titles/1
    def update
      respond_to do |format|
        return if @resource.title == params[:title].squish

        saved = @resource.update(title: params[:title].squish)
        readme_update
        if saved
          format.json do
            render json: @resource.as_json(only: %i[id title], include: :descriptions)
          end
          format.js { render template: 'stash_datacite/shared/update.js.erb' }
        else
          format.html { render :edit }
        end
      end
    end

    private

    def resource
      @resource ||= StashEngine::Resource.find(params[:id])
    end

    def readme_update
      readme = @resource.descriptions.where(description_type: :technicalinfo).first
      return unless readme.try(:description).present?

      previous = resource.versions.map { |v| v.object_changes.slice('title').values.flatten }.reject(&:blank?).map { |a| a[1] }
      newest = previous.pop

      begin
        # udpate JSON in generator
        parsed = JSON.parse(readme.try(:description))
        parsed['title'] = newest
        readme.update(description: parsed.to_json)
      rescue StandardError
        # text replace
        readme.update(description:
          readme.try(:description).gsub(/^\# #{"(#{previous.reverse.map { |t| Regexp.escape(t) }.join('|')}).*$"}/, "# #{newest}"))
      end
    end
  end
end
