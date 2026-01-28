module StashDatacite
  class AuthorsController < ApplicationController
    before_action :check_reorder_valid, only: %i[reorder]
    before_action :set_author, only: %i[update delete invite check_invoice set_invoice]
    before_action :ajax_require_permission, only: %i[update create delete reorder]
    before_action :ajax_require_unsubmitted, only: %i[update create delete reorder]

    respond_to :json

    # GET /authors/new
    def new
      @author = StashEngine::Author.new(resource_id: params[:resource_id])
      respond_to(&:js)
    end

    # POST /authors
    def create
      respond_to do |format|
        @author = StashEngine::Author.create(author_params)
        @author.reload
        format.js
        format.json { render json: @author.as_json(include: :affiliations) }
      end
    end

    # PATCH/PUT /authors/1
    def update
      @author.update(author_params)
      aff = @author.affiliations.pluck(:long_name).sort

      AuthorsService.new(@author).check_orcid
      @author.reload
      process_affiliations

      # IF affiliations changed
      # trigger new version creation manually
      @author.paper_trail.save_with_version if @author.affiliations.pluck(:long_name).sort != aff

      respond_to do |format|
        format.js { render template: 'stash_datacite/shared/update.js.erb' }
        format.json { render json: @author.as_json(include: :affiliations) }
      end
    end

    # DELETE /authors/1
    def delete
      unless params[:id] == 'new'
        @resource = StashEngine::Resource.find(@author.resource_id)
        @author.destroy
      end
      respond_to do |format|
        format.js
        format.json { render json: @author }
      end
    end

    # takes a list of author ids and their new orders like [{id: 3323, order: 0},{id:3324, order: 1}] etc
    def reorder
      respond_to do |format|
        format.json do
          js = params[:author].to_h.to_a.map { |i| { id: i[0], author_order: i[1] } }
          # js = params['_json'].map { |i| { id: i[:id], author_order: i[:order] } } # convert weird params objs to hashes
          grouped_authors = js.index_by { |author| author[:id] }
          resp = StashEngine::Author.update(grouped_authors.keys, grouped_authors.values)
          render json: resp, status: :ok
        end
      end
    end

    def invite
      return unless @author.resource
      return unless %w[submitter collaborator].include?(params[:role])

      respond_to do |format|
        if @author.user.present?
          if params[:role] == 'submitter'
            @author.resource.submitter = @author.user.id
            role = @author.resource.roles.where(role: 'submitter')&.first
          else
            role = @author.resource.roles.find_or_create_by(user_id: @author.user.id)
            return if role.role == 'creator'

            role.update(role: params[:role])
          end
          @author.resource.reload
          StashEngine::UserMailer.invite_user(@author.user, role).deliver_now
        else
          @author.create_edit_code(role: params[:role])
          @author.edit_code.send_invitation
        end
        @author.reload
        format.json do
          render json: {
            author: @author.as_json(include: %i[affiliations edit_code]),
            users: @resource.users.select('stash_engine_users.*', 'stash_engine_roles.role')
          }
        end
      end
    end

    def check_invoice
      inv = Stash::Payments::Invoicer.new(resource: resource, curator: nil)
      customer = inv.retrieve_customer(@author.stripe_customer_id)
      render json: { name: customer&.name, email: customer&.email }
    end

    def set_invoice
      fees = ResourceFeeCalculatorService.new(resource).calculate({ generate_invoice: true })

      if fees[:error] && fees[:old_payment_system]
        # OLD payment system
        inv = Stash::Payments::Invoicer.new(resource: @author.resource, curator: nil)
        customer_id = inv.lookup_prior_stripe_customer_id(params[:customer_email])
        customer_id = inv.create_customer(params[:customer_name], params[:customer_email]).id unless customer_id.present?
        @author.update(stripe_customer_id: customer_id)
      else
        # NEW payment system
        resource_payment = resource.payment || resource.build_payment
        resource_payment.update(
          payment_type: 'stripe',
          pay_with_invoice: true,
          invoice_details: params.permit(%i[customer_email customer_name]).merge({ author_id: @author.id }),
          status: :created,
          amount: fees[:total]
        )
      end

      render json: @author.as_json(include: [:affiliations])
    end

    private

    def resource
      @resource ||= (params[:author] ? StashEngine::Resource.find(author_params[:resource_id]) : @author.resource)
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_author
      return if params[:id] == 'new'

      @author = StashEngine::Author.find((params[:author] ? author_params[:id] : params[:id]))
      ajax_blocked unless resource.id == @author.resource_id # don't let people play games with changing author ids
    end

    # Only allow a trusted parameter "white list" through.
    def author_params
      params.require(:author).permit(:id, :author_first_name, :author_last_name, :author_org_name,
                                     :author_email, :resource_id, :author_orcid, :author_order, :corresp,
                                     affiliation: %i[id ror_id long_name])
    end

    def aff_params
      params.require(:author).permit(:id, :author_first_name, :author_last_name, :author_org_name,
                                     :author_email, :resource_id, :author_orcid, :author_order, :corresp,
                                     affiliations: %i[id ror_id long_name])
    end

    # find correct affiliation based on long_name and ror_id and set it, create one if needed.
    def process_affiliations
      return unless @author.present?

      @author.affiliations.destroy_all
      args = aff_params
      affs = args['affiliations']&.reject { |a| a['long_name'].blank? }
      affs&.each do |aff|
        process_affiliation(aff['long_name'].squish, aff['ror_id'])
      end
    end

    def process_affiliation(name, ror_val)
      return unless @author.present?

      # find a matching pre-existing affiliation
      if ror_val.present?
        # - find by ror_id if avaialable
        affil = StashDatacite::Affiliation.where(ror_id: ror_val).first
      else
        # - find by name otherwise
        affil = StashDatacite::Affiliation.where(long_name: name).first
        affil = StashDatacite::Affiliation.where(long_name: name.to_s).first unless affil.present?
      end

      # if no matching affils found, make a new affil
      if affil.blank?
        affil = if ror_val.present?
                  StashDatacite::Affiliation.create(long_name: name, ror_id: ror_val)
                else
                  StashDatacite::Affiliation.create(long_name: name.to_s, ror_id: nil)
                end
      end

      return if affil.ror_id && @author.affiliations.pluck(:ror_id).include?(affil.ror_id)
      return if affil.ror_id.nil? && @author.affiliations.where(ror_id: nil).pluck(:long_name).include?(affil.long_name)

      @author.affiliation = affil
    end

    def check_reorder_valid
      params.require(:author).permit!
      @authors = StashEngine::Author.where(id: params[:author].keys)

      # you can only order things belonging to one resource
      render json: { error: 'bad request' }, status: :bad_request unless @authors.map(&:resource_id)&.uniq&.length == 1

      @resource = StashEngine::Resource.find(@authors.first&.resource_id) # set resource to check permission to modify
    end

  end
end
