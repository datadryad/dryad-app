module StashEngine
  class CurationActivity < ActiveRecord::Base
    belongs_to :stash_identifier, class_name: 'StashEngine::Identifier', foreign_key: 'identifier_id'
    belongs_to :user, class_name: 'StashEngine::User', foreign_key: 'user_id'
    validates :status, inclusion: { in: ['Unsubmitted',
                                         'Submitted',
                                         'Private for Peer Review',
                                         'Curation',
                                         'Author Action Required',
                                         'Embargoed',
                                         'Published',
                                         'Withdrawn',
                                         'Status Unchanged',
                                         'Versioned'],
                                    message: '%{value} is not a valid status' }
    validates :status, presence: true

    # Callbacks
    # ------------------------------------------
    after_save :submit_to_stripe, :submit_to_datacite
    
    def self.curation_status(my_stash_id)
      curation_activities = CurationActivity.where(stash_identifier: my_stash_id).order(updated_at: :desc)
      curation_activities.each do |activity|
        return activity.status unless activity.status == 'Status Unchanged'
      end
      @curation_status = 'Unsubmitted'
    end

    def as_json(*)
      # {"id":11,"identifier_id":1,"status":"Submitted","user_id":1,"note":"hello hello ssdfs2232343","keywords":null}
      {
        id: id,
        dataset: stash_identifier.to_s,
        status: status,
        action_taken_by: user_name,
        note: note,
        keywords: keywords,
        created_at: created_at,
        updated_at: updated_at
      }
    end

    # Callbacks
    # ------------------------------------------
    def submit_to_stripe
      # Should also check the statuses in the line below so we don't resubmit charges!
      #   e.g. Check the status flags on this object unless we're storing a boolean
      #        somewhere that records that we've already charged them.
      #   `return unless identifier.has_journal? && self.published?`


      # only ask for payment if there is no previous invoice and
      # if the stats has been changed to a published status
      return unless stash_identifier.invoice_id.nil? &&
                    (status == 'Published' || status == 'Embargoed') &&
                    StashEngine.app.payments.service == 'stripe'      

      #TODO -- re-enable this with the chargeable logic 
      #return unless resource.identifier&.chargeable?
      
      Stripe.api_key = StashEngine.app.payments.key
      resource = stash_identifier.resources.first
      
      # ensure a Stripe customer_id exists
      if resource.user.customer_id.nil?
        customer = Stripe::Customer.create(
          :description => resource.user.name,
          :email => resource.user.email,
        )
        resource.user.customer_id = customer.id
        resource.user.save
      end

      invoice_item = Stripe::InvoiceItem.create(
        :customer => resource.user.customer_id,
        :amount => StashEngine.app.payments.data_processing_charge,
        :currency => "usd",
        :description => "Data Processing Charge"
      )
        
      invoice = Stripe::Invoice.create(
        :customer => resource.user.customer_id,
        :description => "Dryad deposit " + stash_identifier.to_s + ", " + resource.title,
        :metadata => {'curator' => user.name},
      )
      stash_identifier.invoice_id = invoice.id
      stash_identifier.save
      invoice.auto_advance = true
      invoice.finalize_invoice
    end

    def submit_to_datacite
      return unless should_update_doi?
      idg = Stash::Doi::IdGen.make_instance(resource: stash_identifier.last_submitted_resource)
      idg.update_identifier_metadata!
    end

    private

    def update_identifier_state
      return if status == 'Status Unchanged'
      return if stash_identifier.nil?
      return if stash_identifier.identifier_state.nil?
      stash_identifier.identifier_state.update_identifier_state(self)
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def should_update_doi?
      # only update if status changed or newly published or embargoed
      return false unless status_changed? && (status == 'Published' || status == 'Embargoed')

      last_merritt_version = stash_identifier&.last_submitted_version_number
      return false if last_merritt_version.nil? # don't submit random crap to DataCite unless it's preserved in Merritt

      # only do UPDATEs with DOIs in production because ID updates like to fail in test EZID/DataCite because they delete their identifiers at random
      return false if last_merritt_version > 1 && Rails.env != 'production'
      true
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    def user_name
      return user.name unless user.nil?
      'System'
    end
  end
end
