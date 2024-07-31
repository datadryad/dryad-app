module StashEngine
  class JournalAdminController < ApplicationController
    helper SortableTableHelper
    before_action :require_user_login
    before_action :setup_paging, only: :index
    before_action :load, only: %i[popup edit]

    def index
      setup_sponsors

      @journals = authorize StashEngine::Journal.all

      if params[:q]
        q = params[:q]
        # search the query in any searchable field
        @journals = @journals.left_outer_joins(:issns).distinct.where('LOWER(title) LIKE LOWER(?) OR stash_engine_journal_issns.id LIKE ?',
                                                             "%#{q.strip}%", "%#{q.strip}%")
      end

      ord = helpers.sortable_table_order(whitelist: %w[title issns payment_plan_type default_to_ppr])
      @journals = @journals.order(ord)

      @journals = @journals.where('sponsor_id= ?', params[:sponsor]) if params[:sponsor].present?

      # paginate for display
      @journals = @journals.page(@page).per(@page_size)
    end

    def popup
      strings = { issn: 'ISSN(s)', payment_plan_type: 'payment plan type', notify_contacts: 'publication contacts',
                  review_contacts: 'PPR contacts', default_to_ppr: 'PPR by default', sponsor_id: 'journal sponsor' }
      @desc = strings[@field.to_sym]
      respond_to(&:js)
    end

    def edit
      valid = %i[default_to_ppr payment_plan_type sponsor_id]
      update = edit_params.slice(*valid)
      update[:sponsor_id] = nil if edit_params.key?(:sponsor_id) && edit_params[:sponsor_id].blank?
      update[:payment_plan_type] = nil if edit_params.key?(:payment_plan_type) && edit_params[:payment_plan_type].blank?
      update_issns if edit_params[:issn].present?
      update[:notify_contacts] = edit_params[:notify_contacts].split("\n").map(&:strip).to_json if edit_params[:notify_contacts].present?
      update[:review_contacts] = edit_params[:review_contacts].split("\n").map(&:strip).to_json if edit_params[:review_contacts].present?
      @journal.update(update)

      respond_to(&:js)
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

    def load
      @journal = authorize StashEngine::Journal.find(params[:id]), :popup?
      @field = params[:field]
    end

    def update_issns
      issns = edit_params[:issn].split("\n").map(&:strip)
      @journal.issns.where.not(id: issns).destroy_all
      issns.reject { |id| @journal.issns.map(&:id).include?(id) }.each { |issn| StashEngine::JournalIssn.create(id: issn, journal_id: @journal.id) }
      @journal.reload
    end

    def edit_params
      params.permit(:id, :field, :issn, :payment_plan_type, :notify_contacts, :review_contacts, :default_to_ppr, :sponsor_id)
    end

  end
end
