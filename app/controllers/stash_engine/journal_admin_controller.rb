module StashEngine
  class JournalAdminController < ApplicationController
    helper SortableTableHelper
    before_action :require_user_login
    before_action :require_superuser
    before_action :setup_paging, only: :index
    before_action :load, only: %i[popup edit]

    def index
      setup_sponsors

      @journals = StashEngine::Journal.all

      if params[:q]
        q = params[:q]
        # search the query in any searchable field
        @journals = @journals.where('title LIKE ? OR issn LIKE ?', "%#{q}%", "%#{q}%")
      end

      ord = helpers.sortable_table_order(whitelist: %w[title issn payment_plan_type default_to_ppr])
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
      update[:sponsor_id] = nil if edit_params[:sponsor_id].blank?
      update[:payment_plan_type] = nil if edit_params[:payment_plan_type].blank?
      update[:issn] = edit_params[:issn].split("\n").map(&:strip).to_json if edit_params[:issn]
      update[:notify_contacts] = edit_params[:notify_contacts].split("\n").map(&:strip).to_json if edit_params[:notify_contacts]
      update[:review_contacts] = edit_params[:review_contacts].split("\n").map(&:strip).to_json if edit_params[:review_contacts]
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
      @sponsors = [OpenStruct.new(id: '', name: '*Select publisher*')]
      @sponsors << StashEngine::JournalOrganization.all.map { |o| OpenStruct.new(id: o.id, name: o.name) }
      @sponsors.flatten!
    end

    def load
      @journal = authorize StashEngine::Journal.find(params[:id]), :load?
      @field = params[:field]
    end

    def edit_params
      params.permit(:id, :field, :issn, :payment_plan_type, :notify_contacts, :review_contacts, :default_to_ppr, :sponsor_id)
    end

  end
end
