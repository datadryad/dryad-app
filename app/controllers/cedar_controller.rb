class CedarController < ApplicationController
  # Since the CEDAR form doesn't know about Rails, we don't use the default Rails CSRF validation.
  # Instead we pass the CSRF token as an "info" value in the form, and validate it explicitly in the save method
  skip_before_action :verify_authenticity_token, only: [:save]

  def json_config
    json_output = {
      showSampleTemplateLinks: false,
      terminologyIntegratedSearchUrl: 'https://terminology.metadatacenter.org/bioportal/integrated-search',

      sampleTemplateLocationPrefix: '/cedar/',
      loadSampleTemplateName: params[:template],
      expandedSampleTemplateLinks: false,

      showTemplateRenderingRepresentation: false,
      showInstanceDataCore: false,
      expandedInstanceDataCore: false,
      showMultiInstanceInfo: false,
      expandedMultiInstanceInfo: false,

      expandedTemplateRenderingRepresentation: false,
      showInstanceDataFull: true,
      expandedInstanceDataFull: false,
      showTemplateSourceData: false,
      expandedTemplateSourceData: false,

      showHeader: false,
      showFooter: false,

      defaultLanguage: 'en',
      fallbackLanguage: 'en',

      collapseStaticComponents: false,
      showStaticText: true,
      showAllMultiInstanceValues: false
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
    render json: { check: templates.present?, templates: templates.reject(&:blank?) }.to_json
  end

  def template
    render json: CedarTemplate.find_by(id: params[:id]).template
  end

  def metadata
    render json: { note: 'Metadata loaded separately' }.to_json
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

  private

  def json_params
    j = params.permit(:json, :template_id)
    j[:json] = JSON.parse(j[:json])
    j
  end
end
