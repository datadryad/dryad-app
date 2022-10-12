class CedarController < ApplicationController
  skip_before_action :verify_authenticity_token

  def json_config
    json_output = {
      "showTemplateUpload": false,
      "templateUploadBaseUrl": 'https://api-php.cee.metadatacenter.org',
      "templateUploadEndpoint": '/upload_not_used',
      "templateDownloadEndpoint": '/download_not_used',

      "showDataSaver": true,
      "dataSaverEndpointUrl": '/cedar-save',

      "showSampleTemplateLinks": false,
      "expandedSampleTemplateLinks": false,
      "sampleTemplateLocationPrefix": 'https://component.staging.metadatacenter.org/cedar-embeddable-editor-sample-templates/',
      "loadSampleTemplateName": params[:template],

      "showFooter": false,
      "showHeader": false,

      "terminologyProxyUrl": 'https://terminology.metadatacenter.org/bioportal/integrated-search',

      "showTemplateRenderingRepresentation": false,
      "showMultiInstanceInfo": false,
      "showTemplateSourceData": false,
      "showInstanceDataCore": false,
      "showInstanceDataFull": true,

      "expandedInstanceDataCore": false,
      "expandedInstanceDataFull": false,
      "expandedTemplateSourceData": false,
      "expandedTemplateRenderingRepresentation": false,
      "expandedMultiInstanceInfo": false
    }

    respond_to do |format|
      format.any { render json: json_output }
    end
  end

  # Save data from the Cedar editor into the database
  def save
    # csrf = params['info']['csrf']
    resource = StashEngine::Resource.find(params['info']['resource_id']&.to_i)
    render json: { error: 'resource-not-found' }.to_json, status: 404 unless resource.present?

    merged = params['info'].merge(metadata: params['metadata'])
    cedar_json = merged.to_json(except: %i[resource_id csrf])
    resource.update(cedar_json: cedar_json)
    resource.reload

    respond_to do |format|
      format.any { render json: { message: 'Save value received in the Cedar Save method' } }
    end
  end
end
