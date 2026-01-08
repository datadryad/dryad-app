class CedarTemplateController < ApplicationController
  include StashEngine::SharedController
  include StashEngine::SharedSecurityController
  helper StashEngine::SortableTableHelper
  before_action :require_user_login
  layout 'stash_engine/application'

  def index
    setup_paging
    @templates = authorize CedarTemplate.all.includes([:cedar_word_bank])

    if params[:q]
      q = params[:q]
      @templates = @templates.where('LOWER(title) LIKE LOWER(?)', "%#{q}%")
    end
    @templates = @templates.where(word_bank_id: params[:word_bank_id]) if params[:word_bank_id]

    ord = helpers.sortable_table_order(whitelist: %w[title word_bank_id])
    @templates = @templates.order(ord)
    @templates = @templates.page(@page).per(@page_size)
  end

  def new
    @template = authorize CedarTemplate.new
  end

  def create
    @template = authorize CedarTemplate.create(create_params)
    render js: "window.location.search = '?q=#{@template.title}'"
  end

  def edit
    @template = authorize CedarTemplate.find_by(id: params[:id])
  end

  def update
    @template = authorize CedarTemplate.find_by(id: params[:id])
    @template.update(update_params)
  end

  private

  def setup_paging
    @page = params[:page] || '1'
    @page_size = if params[:page_size].blank? || params[:page_size].to_i == 0
                   10
                 else
                   params[:page_size].to_i
                 end
  end

  def create_params
    c = params.permit(:id, :title, :template, :word_bank_id)
    c[:template] = JSON.parse(c[:template])
    c
  end

  def update_params
    params.permit(:word_bank_id)
  end
end
