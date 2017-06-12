require_dependency 'stash_engine/application_controller'
require 'stash/merritt/builders'

module StashEngine
  class ManifestsController < ApplicationController

    before_action :resource_and_fn

    NAMES_AND_METHODS = {
      'stash-wrapper' => :stash_wrapper, # xml
      'mrt-datacite'            =>  :datacite, # xml
      'mrt-oaidc'               =>  :oaidc, # xml
      'mrt-dataone-manifest'    =>  :dataone, # txt
      'mrt-delete'              =>  :mrt_delete, # txt
      'mrt-embargo'             =>  :mrt_embargo # txt
    }.freeze

    def show
      unless NAMES_AND_METHODS.keys.include?(@fn)
        render(plain: 'not found', status: 404) && (return false)
      end

      respond_to do |format|
        format.xml { render xml: send(NAMES_AND_METHODS[@fn]) }
        format.text { render plain: send(NAMES_AND_METHODS[@fn]) }
      end
    end

    private

    def resource_and_fn
      @resource = Resource.find(params[:id])
      @fn = params[:filename]
    end

    def stash_wrapper
      sp = Stash::Merritt::SubmissionPackage.new(resource: @resource, packaging: nil)
      b = Stash::Merritt::Builders::StashWrapperBuilder.new(dcs_resource: sp.dc4_resource,
                                                            version_number: sp.version_number, uploads: sp.uploads, embargo_end_date: sp.embargo_end_date)
      b.contents
    end

    def datacite
      sp = Stash::Merritt::SubmissionPackage.new(resource: @resource, packaging: nil)
      b = Stash::Merritt::Builders::MerrittDataciteBuilder.new(sp.datacite_xml_factory)
      b.contents
    end

    def oaidc
      b = Stash::Merritt::Builders::MerrittOAIDCBuilder.new(resource_id: @resource.id)
      b.contents
    end

    def dataone
      uploads = @resource.file_uploads.where(file_state: 'created')
      b = Stash::Merritt::Builders::DataONEManifestBuilder.new(uploads)
      b.contents
    end

    def mrt_delete
      b = Stash::Merritt::Builders::MerrittDeleteBuilder.new(resource_id: @resource.id)
      b.contents.to_s
    end

    def mrt_embargo
      b = Stash::Merritt::Builders::MerrittEmbargoBuilder.new(embargo_end_date: (@resource.embargo && @resource.embargo.end_date))
      b.contents
    end
  end
end
