module Submission
  class ResourcesService
    attr_reader :resource_id, :resource

    def initialize(resource_id)
      @resource_id = resource_id
      @resource = StashEngine::Resource.find(resource_id)
    end

    def trigger_submission
      resource.current_state = 'processing'
      Submission::SubmissionJob.perform_async(resource_id)
    end

    def submit
      Rails.logger.info("Submitting resource #{resource_id} (#{resource.identifier_str})\n")
      resource.update_repo_queue_state(state: 'processing')
      handle_invoice_creation

      # only copy newly created files
      new_files = resource.data_files.newly_created
      if new_files.any?
        redis_key = SUBMISSION_REDIS_KEY.gsub('%{resource.id}', resource_id.to_s)
        Sidekiq.redis { |r| r.set(redis_key, new_files.count) }

        new_files.each do |file|
          Submission::CopyFileJob.perform_async(file.id)
        end
      else
        Submission::CheckStatusJob.perform_async(resource_id)
      end
    end

    # Register that a dataset has completed processing into the storage system
    def finalize
      return unless resource.present?
      return unless resource == resource.identifier&.processing_resource

      resource.download_uri = resource.s3_dir_name(type: 'data')
      resource.current_state = 'submitted'
      saved = resource.save
      @resource.reload
      saved
    end

    def cleanup_files
      remove_public_dir # where the local manifest file is stored
      remove_submission_data_files
    rescue StandardError => e
      msg = "An unexpected error occurred when cleaning up files for resource #{resource.id}: "
      msg << e.full_message
      logger.warn(msg)
    end

    def hold_submissions?
      File.exist?(File.expand_path(File.join(Rails.root, '..', 'hold-submissions.txt')))
    end

    private

    def handle_invoice_creation
      # this method is for 2025 payment system
      # old payment system id generating an invoice on publish
      return if resource.identifier.old_payment_system

      payment = resource.payment
      if payment.nil?
        if resource.identifier.waiver? && resource.identifier.payment_id.blank?
          payment = create_missing_invoice
          return if payment.nil?
        else
          Rails.logger.warn("No payment found for resource ID #{resource.id}")
          return
        end
      end

      if payment && !payment.pay_with_invoice
        Rails.logger.warn("Payment for resource ID #{resource.id} is not set to invoice")
        return
      end

      invoicer = Stash::Payments::StripeInvoicer.new(resource)
      invoicer.handle_customer(payment.invoice_details)
      invoice = invoicer.create_invoice
      return unless invoice

      payment.update(pay_with_invoice: true, invoice_id: invoice.id)
      resource.identifier.update(payment_type: 'stripe', payment_id: invoice.id)
    end

    def create_missing_invoice
      payment_service = PaymentsService.new(nil, resource, {})
      if payment_service.total_amount > 0
        Rails.logger.warn("No payment needed for resource ID #{resource.id} as waiver that should pay LDF rate")
        return
      end
      payment = resource.build_payment
      payment.update(
        payment_type: 'stripe',
        pay_with_invoice: true,
        status: :created,
        amount: 0,
        has_discount: payment_service.has_discount,
        invoice_details: {
          author_id: resource.owner_author.id,
          customer_name: resource.owner_author.author_full_name,
          customer_email: resource.owner_author.author_email
        }
      )
      payment
    rescue StandardError => e
      Rails.logger.warn("Error creating waiver payment for #{resource.id}, error: #{e.full_message}")
      nil
    end

    def remove_public_dir
      res_public_dir = Rails.public_path.join('system').join(resource.id.to_s)
      remove_if_exists(res_public_dir)
    end

    def remove_submission_data_files
      Stash::Aws::S3.new.delete_dir(s3_key: resource.s3_dir_name(type: 'manifest').to_s)
      Stash::Aws::S3.new.delete_dir(s3_key: resource.s3_dir_name(type: 'data').to_s)
    end

    def remove_if_exists(file)
      return if file.blank?

      FileUtils.remove_entry_secure(file, true)
    end
  end
end
