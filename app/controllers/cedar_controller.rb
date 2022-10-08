class CedarController < ApplicationController
  skip_before_action :verify_authenticity_token

  def get_config
    puts "CEDAR get_configa"
    json_output = {
                   "showTemplateUpload": false,
                   "templateUploadBaseUrl": "https://api-php.cee.metadatacenter.org",
                   "templateUploadEndpoint": "/upload_not_used",
                   "templateDownloadEndpoint": "/download_not_used",
                   
                   "showDataSaver": true,
                   "dataSaverEndpointUrl": "/cedar-save", #Rails.application.routes.url_helpers.root_url + 
                   
                   "showSampleTemplateLinks": false,
                   "expandedSampleTemplateLinks": false,
                   "sampleTemplateLocationPrefix": "https://component.staging.metadatacenter.org/cedar-embeddable-editor-sample-templates/",
                   "xxxsampleTemplateLocationPrefix": "http://ryandash.datadryad.org/cedar-embeddable-editor/",
                   "loadSampleTemplateName": params[:template],
                   
                   "showFooter": false,
                   "showHeader": false,
                   
                   "terminologyProxyUrl": "https://terminology.metadatacenter.org/bioportal/integrated-search",
                   
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
    csrf = params['info']['csrf']
    resource = StashEngine::Resource.find(params['info']['resource_id']&.to_i)

    # testing csrf token
    puts "csrf #{csrf}"
    puts "session #{session}"
    
    if !resource
      # TODO actual return of http error
      return "ERROR"
    end

    puts "Found resource #{resource.id}"
    merged = params['info'].merge(metadata: params['metadata'])
    cedar_json = merged.to_json(except: [:resource_id, :csrf])

    resource.update(cedar_json: cedar_json)

    resource.reload
    puts "json #{resource.cedar_json}"
    puts "json input #{resource.cedar_json['Input Field']}"
    # TODO
    # close modal on successful save
    # - add some kind of listener for it?
    # fix the handling of the CSRF token
    
    respond_to do |format|
      format.any { render json: { message: 'Save value received in the Cedar Save method' } }
    end
  end
end
