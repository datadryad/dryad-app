require_dependency 'stash_datacite/application_controller'

module StashDatacite
  class PublicationsController < ApplicationController

    # PATCH/PUT /publications/1
    def update
      @se_id = StashEngine::Identifier.find(params[:internal_datum][:identifier_id])
      @pub_issn = StashEngine::InternalDatum.find_by(stash_identifier: @se_id, data_type: 'publicationISSN')
      @pub_issn = StashEngine::InternalDatum.new(stash_identifier: @se_id, data_type: 'publicationISSN') if @pub_issn.nil?

      @msid = StashEngine::InternalDatum.find_by(stash_identifier: @se_id, data_type: 'manuscriptNumber')
      @msid = StashEngine::InternalDatum.new(stash_identifier: @se_id, data_type: 'manuscriptNumber') if @msid.nil?
      respond_to do |format|
        format.js { render template: 'stash_datacite/shared/update.js.erb' } if @pub_issn.update(value: params[:internal_datum][:publication_issn])
        format.js { render template: 'stash_datacite/shared/update.js.erb' } if @msid.update(value: params[:internal_datum][:msid])
      end
    end

    private
  end
end

