module StashDatacite
  class TitlesController < ApplicationController

    before_action :ajax_require_modifiable, only: [:update]

    respond_to :json

    # PATCH/PUT /titles/1
    def update
      respond_to do |format|
        html_title = ActionController::Base.helpers.sanitize(
          Nokogiri::HTML5.fragment(
            helpers.markdown_render(content: CGI.escapeHTML(params[:title].squish))
          ).css('p').inner_html,
          tags: %w[em sub sup i]
        )

        return if @resource.title == html_title

        saved = @resource.update(title: html_title)

        if saved
          readme_update
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

      previous = resource.versions.map { |v| v.object_changes.slice('title').values.flatten }.reject(&:blank?).map do |a|
        a[1].gsub(%r{</?(em|i)>}, '*').gsub(%r{</?sup>}, '^').gsub(%r{</?sub>}, '~')
      end
      newest = previous.pop

      begin
        # udpate JSON in generator
        parsed = JSON.parse(readme.try(:description))
        parsed['title'] = newest
        readme.update(description: parsed.to_json)
      rescue StandardError
        # text replace
        readme.update(description:
          readme.description.gsub(/^\# #{"(#{previous.reverse.map { |t| Regexp.escape(t) }.join('|')}).*$"}/, "# #{newest}"))
      end
      true
    end
  end
end
