class CedarController < ApplicationController
  # Since the CEDAR form doesn't know about Rails, we don't use the default Rails CSRF validation.
  # Instead we pass the CSRF token as an "info" value in the form, and validate it explicitly in the save method
  skip_before_action :verify_authenticity_token, only: [:save]

  def json_config
    json_output = {
      showSampleTemplateLinks: false,
      terminologyIntegratedSearchUrl: 'https://terminology.metadatacenter.org/bioportal/integrated-search',

      sampleTemplateLocationPrefix: '/cedar-embeddable-editor/templates',
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
      showStaticText: true
    }

    respond_to do |format|
      format.any { render json: json_output }
    end
  end

  # Save data from the Cedar editor into the database
  def save
    # If the CSRF token is not present or not valid, don't save the data
    csrf = params['info']['csrf']
    return unless csrf && valid_authenticity_token?(session, csrf)

    resource = StashEngine::Resource.find(params['info']['resource_id']&.to_i)
    render json: { error: 'resource-not-found' }.to_json, status: 404 unless resource.present?

    merged = params['info'].merge(metadata: params['metadata'])
    cedar_json = merged.to_json(except: %i[resource_id csrf])
    resource.update(cedar_json: cedar_json)
    resource.reload

    render json: { message: 'Save value received in the Cedar Save method' }
  end
end
