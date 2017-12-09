require_dependency "stash_api/application_controller"

module StashApi
  class DatasetsController < ApplicationController

    UNACCEPTABLE_MSG = '406 - unacceptable: please set your Content-Type and Accept headers for application/json'

    # get /datasets/<id>
    def show
      ds = Dataset.new(identifier: params[:id])
      respond_to do |format|
        format.json { render json: ds.metadata }
        format.xml { render xml: ds.metadata.to_xml(root: 'dataset') }
        format.html { render text: UNACCEPTABLE_MSG, status: 406 }
      end
    end

    # get /datasets
    def index
      datasets = all_datasets
      respond_to do |format|
        format.json { render json: datasets }
        format.xml { render xml: datasets.to_xml(root: 'datasets') }
        format.html { render text: UNACCEPTABLE_MSG, status: 406 }
      end
    end

    private

    def all_datasets
      {'stash:datasets' =>
          StashEngine::Identifier.all.map {|i| Dataset.new(identifier: "#{i.identifier_type}:#{i.identifier}").metadata } }
    end


  end
end
