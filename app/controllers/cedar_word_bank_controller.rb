class CedarWordBankController < ApplicationController
  include StashEngine::SharedController
  include StashEngine::SharedSecurityController
  helper StashEngine::SortableTableHelper
  before_action :require_user_login
  layout 'stash_engine/application'

  def index
    setup_paging
    @banks = authorize CedarWordBank.all

    if params[:q]
      q = params[:q]
      # search the query in any searchable field
      @banks = @banks.where('LOWER(label) LIKE LOWER(?) OR LOWER(keywords) LIKE LOWER(?)', "%#{q}%", "%#{q}%")
    end

    ord = helpers.sortable_table_order(whitelist: %w[label])
    @banks = @banks.order(ord)
    @banks = @banks.page(@page).per(@page_size)
  end

  def new
    @bank = authorize CedarWordBank.new
  end

  def create
    @bank = authorize CedarWordBank.create(create_params)
    render js: "window.location.search = '?q=#{@bank.label}'"
  end

  def edit
    @bank = authorize CedarWordBank.find_by(id: params[:id])
  end

  def update
    @bank = authorize CedarWordBank.find_by(id: params[:id])
    @bank.update(create_params)
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
    params.permit(:label, :keywords)
  end
end
