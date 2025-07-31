module StashEngine
  class JournalAdminController < ApplicationController
    helper SortableTableHelper
    before_action :require_user_login
    before_action :setup_paging, only: :index

    def index
      setup_sponsors

      @journals = authorize StashEngine::Journal.left_outer_joins(%i[issns sponsor flag payment_configuration])

      if params[:q]
        q = params[:q]
        # search the query in any searchable field
        @journals = @journals.select('stash_engine_journals.*, payment_configurations.payment_plan')
          .left_outer_joins(:issns, :alternate_titles, :payment_configuration)
          .distinct
          .where(
            'LOWER(stash_engine_journals.title) LIKE LOWER(?)
            OR LOWER(stash_engine_journal_titles.title) LIKE LOWER(?)
            OR stash_engine_journal_issns.id LIKE ?',
            "%#{q.strip}%", "%#{q.strip}%", "%#{q.strip}%"
          )
      end

      ord = helpers.sortable_table_order(whitelist: %w[title issns payment_plan default_to_ppr])
      @journals = @journals.order(ord)

      @journals = @journals.where('sponsor_id= ?', params[:sponsor]) if params[:sponsor].present?

      # paginate for display
      @journals = @journals.page(@page).per(@page_size)
    end

    def edit
      @journal = authorize StashEngine::Journal.find(params[:id])
      @payment_configuration = @journal.payment_configuration || @journal.build_payment_configuration
      respond_to(&:js)
    end

    def update
      @journal = authorize StashEngine::Journal.find(params[:id])
      @journal.update(update_hash)
      errs = @journal.errors.full_messages
      @journal.issns.each { |is| errs.concat(is.errors.full_messages) }
      if errs.any?
        @error_message = errs[0]
        render 'stash_engine/user_admin/update_error' and return
      end
      respond_to(&:js)
    end

    def new
      @journal = authorize StashEngine::Journal.new
      @payment_configuration = @journal.build_payment_configuration
      respond_to(&:js)
    end

    def create
      @journal = StashEngine::Journal.create(update_hash)
      errs = @journal.errors.full_messages
      @journal.issns.each { |is| errs.concat(is.errors.full_messages) }
      if errs.any?
        @error_message = errs[0]
        render 'stash_engine/user_admin/update_error' and return
      end
      render js: "window.location.search = '?q=#{@journal.single_issn}'"
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
      pp edit_params
      valid = %i[title preprint_server default_to_ppr allow_review_workflow manuscript_number_regex peer_review_custom_text
                 payment_configuration_attributes]
      update = edit_params.slice(*valid).to_h
      update[:sponsor_id] = edit_params[:sponsor_id].presence
      %i[api_contacts notify_contacts review_contacts].each do |contacts|
        update[contacts] = edit_params[contacts].to_s.split("\n").map(&:strip).to_json
      end
      update[:issns_attributes] = update_issns
      update[:alternate_titles_attributes] = update_alts
      if edit_params.key?(:flag)
        update[:flag_attributes] = { note: edit_params[:note] }
        update[:flag_attributes][:id] = @journal.flag.id if @journal&.flag.present?
      elsif @journal&.flag.present?
        @journal.flag.delete
      end
      update
    end

    def update_issns
      issns = edit_params[:issn].split("\n").map(&:strip)
      return issns.map { |id| { issn: id } } unless @journal&.issns&.any?

      @journal.issns.where.not(id: issns).destroy_all
      issns.reject { |id| @journal.issns.map(&:id).include?(id) }.map { |id| { issn: id } }
    end

    def update_alts
      alts = edit_params[:alt_title].split("\n").map(&:strip)
      return alts.map { |str| { title: str } } unless @journal&.alternate_titles&.any?

      @journal.alternate_titles.where.not(title: alts).destroy_all
      alts.reject { |str| @journal.alternate_titles.map(&:title).include?(str) }.map { |str| { title: str } }
    end

    def edit_params
      params.permit(:id, :title, :issn, :alt_title, :notify_contacts, :review_contacts, :api_contacts,
                    :preprint_server, :manuscript_number_regex, :peer_review_custom_text, :sponsor_id,
                    :default_to_ppr, :allow_review_workflow, :flag, :note,
                    payment_configuration_attributes: %i[id payment_plan covers_ldf ldf_limit])
    end
  end
end
