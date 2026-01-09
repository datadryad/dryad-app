class CedarController < ApplicationController
  # Since the CEDAR form doesn't know about Rails, we don't use the default Rails CSRF validation.
  # Instead we pass the CSRF token as an "info" value in the form, and validate it explicitly in the save method
  skip_before_action :verify_authenticity_token, only: [:save]

  def json_config
    json_output = {
      sampleTemplateLocationPrefix: '/cedar/',
      loadSampleTemplateName: "#{params[:template]}#{params.key?(:viewer) ? "/#{params[:resource_id]}" : ''}",
      readOnlyMode: params.key?(:viewer),
      hideEmptyFields: params.key?(:viewer),

      showSampleTemplateLinks: false,
      expandedSampleTemplateLinks: false,
      showTemplateRenderingRepresentation: false,
      expandedTemplateRenderingRepresentation: false,
      showInstanceDataCore: false,
      expandedInstanceDataCore: false,
      showMultiInstanceInfo: false,
      expandedMultiInstanceInfo: false,
      showAllMultiInstanceValues: false,
      showInstanceDataFull: false,
      expandedInstanceDataFull: false,
      showTemplateSourceData: false,
      expandedTemplateSourceData: false,

      showHeader: false,
      showFooter: false,

      defaultLanguage: 'en',
      fallbackLanguage: 'en',

      collapseStaticComponents: false,
      showStaticText: !params.key?(:viewer)
    }

    respond_to do |format|
      format.any { render json: json_output }
    end
  end

  def check
    resource = StashEngine::Resource.find_by(id: params[:resource_id])
    abstract = resource.descriptions.type_abstract.first&.description
    journal = resource.resource_publication&.publication_name
    search_string = [resource.title, abstract, journal, resource.subjects&.map(&:subject)].flatten.reject(&:blank?).join(' ')
    group = CedarWordBank.where("REGEXP_LIKE(?, keywords, 'i')", search_string)
    templates = group.first&.cedar_templates&.select(:id, :title) || []
    templates |= CedarTemplate.where(id: resource.cedar_json.template_id)&.select(:id, :title) if resource.cedar_json.present?
    render json: { check: templates.present?, templates: templates }.to_json
  end

  def template
    render json: CedarTemplate.find_by(id: params[:id]).template
  end

  def metadata
    resource = StashEngine::Resource.find_by(id: params[:resource_id])
    render json: resource.cedar_json.json
  end

  def save
    resource = StashEngine::Resource.find_by(id: params[:resource_id])
    render json: { error: 'resource-not-found' }.to_json, status: 404 unless resource.present?
    if resource.cedar_json.present?
      resource.cedar_json.update(json_params)
    else
      resource.create_cedar_json(json_params)
    end
    render json: resource.cedar_json.as_json
  end

  def delete
    resource = StashEngine::Resource.find_by(id: params[:resource_id])
    render json: { error: 'resource-not-found' }.to_json, status: 404 unless resource.present?
    resource.cedar_json.destroy
    render json: { message: 'CEDAR file destroyed' }
  end

  def preview
    @resource = StashEngine::Resource.find_by(id: params[:resource_id])
    @template = @resource.cedar_json.cedar_template
    render template: 'stash_engine/downloads/preview_cedar', formats: [:js]
  end

  private

  def json_params
    j = params.permit(:json, :template_id)
    j[:json] = JSON.parse(j[:json])
    j
  end
end
