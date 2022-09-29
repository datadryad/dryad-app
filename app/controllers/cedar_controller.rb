class CedarController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  def save
    puts "I'M IN THE CEDAR SAVE CONTROLLER"

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
    cedar_json = merged.to_json(:except => [:resource_id, :csrf])

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
