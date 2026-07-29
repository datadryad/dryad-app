class ResearchIntegrityCaseController < ApplicationController
  include StashEngine::SharedController
  include StashEngine::SharedSecurityController

  helper StashEngine::SortableTableHelper
  layout 'stash_engine/application'

  before_action :require_user_login
  before_action :setup_paging, only: %i[index history]

  def index
    @cases = authorize ResearchIntegrityCase.unresolved.joins(identifier: [:latest_resource])
    setup_search if params[:q]
    @cases = @cases.page(@page).per(@page_size)
  end

  def history
    @cases = authorize ResearchIntegrityCase.resolved.joins(identifier: [:latest_resource])
    setup_search if params[:q]
    @cases = @cases.page(@page).per(@page_size)
  end

  def edit
    @case = authorize ResearchIntegrityCase.find_by(id: params[:id])
    respond_to(&:js)
  end

  def update
    @case = authorize ResearchIntegrityCase.find_by(id: params[:id])
    @case.update(up_params)
    @resolve = up_params.key?(:resolved)
    respond_to(&:js)
  end

  private

  def setup_paging
    @page = params[:page] || 1
    @page_size = 10 if params[:page_size].blank? || params[:page_size].to_i == 0
    @page_size ||= params[:page_size].to_i
  end

  def setup_search
    @cases = @cases.where(
      'research_integrity_cases.notes like ? or stash_engine_identifiers.identifier like ? or stash_engine_resources.title like ?',
      "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%"
    )
  end

  def up_params
    params.permit(:notes, :resolved)
  end

end
