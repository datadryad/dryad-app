module StashEngine
  class JournalAdminController < ApplicationController
    helper SortableTableHelper
    before_action :require_user_login
    before_action :setup_paging, only: :index

    def index
      setup_sponsors

      @journals = authorize StashEngine::Journal.includes(%i[issns sponsor])

      if params[:q]
        q = params[:q]
        # search the query in any searchable field
        @journals = @journals.left_outer_joins(:issns).distinct
          .where('LOWER(title) LIKE LOWER(?) OR stash_engine_journal_issns.id LIKE ?', "%#{q.strip}%", "%#{q.strip}%")
      end

      ord = helpers.sortable_table_order(whitelist: %w[title issns payment_plan_type default_to_ppr])
      @journals = @journals.order(ord)

      @journals = @journals.where('sponsor_id= ?', params[:sponsor]) if params[:sponsor].present?

      # paginate for display
      @journals = @journals.page(@page).per(@page_size)
    end

    def edit
      @journal = authorize StashEngine::Journal.find(params[:id])
      respond_to(&:js)
    end

    def update
      @journal = authorize StashEngine::Journal.find(params[:id])
      @journal.update(update_hash)
      update_issns if edit_params.key?(:issn)
      respond_to(&:js)
    end

    def new
      @journal = authorize StashEngine::Journal.new
      respond_to(&:js)
    end

    def create
      @journal = StashEngine::Journal.create(update_hash)
      update_issns if edit_params.key?(:issn)
      redirect_to action: 'index', q: @journal.single_issn
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

    def setup_sponsors
      @sponsors = [OpenStruct.new(id: '', name: '')]
      @sponsors << StashEngine::JournalOrganization.all.order(:name).map { |o| OpenStruct.new(id: o.id, name: o.name) }
      @sponsors.flatten!
    end

    def update_hash
      valid = %i[title default_to_ppr payment_plan_type sponsor_id]
      update = edit_params.slice(*valid)
      update[:sponsor_id] = nil if edit_params.key?(:sponsor_id) && edit_params[:sponsor_id].blank?
      update[:payment_plan_type] = nil if edit_params.key?(:payment_plan_type) && edit_params[:payment_plan_type].blank?
      update[:notify_contacts] = edit_params[:notify_contacts].split("\n").map(&:strip).to_json if edit_params.key?(:notify_contacts)
      update[:review_contacts] = edit_params[:review_contacts].split("\n").map(&:strip).to_json if edit_params.key?(:review_contacts)
      update
    end

    def update_issns
      issns = edit_params[:issn].split("\n").map(&:strip)
      @journal.issns.where.not(id: issns).destroy_all
      issns.reject { |id| @journal.issns.map(&:id).include?(id) }.each do |issn|
        errs = StashEngine::JournalIssn.create(id: issn, journal_id: @journal.id).errors.full_messages
        if errs.any?
          @error_message = errs[0]
          render :update_error and break
        end
        StashEngine::JournalIssn.create(id: issn, journal_id: @journal.id)
      end
      @journal.reload
    rescue ActiveRecord::RecordNotUnique
      @error_message = 'ISSN is already in use'
      render :update_error and return
    end

    def edit_params
      params.permit(:id, :title, :issn, :payment_plan_type, :notify_contacts, :review_contacts, :default_to_ppr, :sponsor_id)
    end

  end
end
