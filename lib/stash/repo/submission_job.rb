require 'rails'
require 'down'
require 'active_record'
require 'concurrent/promise'
require 'byebug'
require 'stash/aws/s3'

module Stash
  module Repo
    class SubmissionJob
      attr_reader :resource_id

      def initialize(resource_id:)
        resource_id = resource_id.to_i if resource_id.is_a?(String)
        raise ArgumentError, "Invalid resource ID: #{resource_id || 'nil'}" unless resource_id.is_a?(Integer)

        @resource_id = resource_id
      end

      # Executes this task and returns a result, or throws an error. Any ActiveRecord
      # models needed by the task should be created in this method, and should not
      # be returned, yielded, thrown, or passed outside it.
      # this is where it actually starts running the real submission whenever it activates from the promise
      #
      # @return [SubmissionResult] the result of the task.
      def submit!
        logger.info("#{Time.now.xmlschema} #{description}")
        previously_submitted = StashEngine::RepoQueueState.where(resource_id: @resource_id, state: 'processing').count.positive?
        if Stash::Repo::Repository.hold_submissions?
          # to mark that it needs to be re-enqueued and processed later
          Stash::Repo::Repository.update_repo_queue_state(resource_id: @resource_id, state: 'rejected_shutting_down')
        elsif previously_submitted
          # Do not send to the repo again if it has already been sent. If we need to re-send we'll have to delete the statuses
          # and re-submit manually.  This should be an exceptional case that we send the same resource more than once.
          latest_queue = StashEngine::RepoQueueState.latest(resource_id: @resource_id)
          latest_queue.destroy if latest_queue.present? && (latest_queue.state == 'enqueued')
        else
          Stash::Repo::Repository.update_repo_queue_state(resource_id: @resource_id, state: 'processing')
          do_submit!
        end
      rescue StandardError => e
        Stash::Repo::SubmissionResult.failure(resource_id: resource_id, request_desc: description, error: e)
      end

      # Describes this submission job. This may include the resource ID, the type
      # of submission (create vs. update), and any configuration information (repository
      # URLs etc.) useful for debugging, but should not include any secret information
      # such as repository credentials, as it will be logged.
      # return [String] a description of the job
      def description
        @description ||= begin
          resource = StashEngine::Resource.find(resource_id)
          description_for(resource)
        rescue StandardError => e
          logger.error("Can't find resource #{resource_id}: #{e}\n#{e.full_message}\n")
          "#{self.class} for missing resource #{resource_id}"
        end
      end

      # Executes this task asynchronously and with its own ActiveRecord connection.
      # @return [Promise<SubmissionResult>] a Promise that will provide the result of this job
      def submit_async(executor:)
        Concurrent::Promise.new(executor: executor) { ActiveRecord::Base.connection_pool.with_connection { submit! } }.execute
      end

      def logger
        Rails.logger
      end

      private

      def do_submit!
        handle_invoice_creation
        logger.info("Submitting resource #{resource_id} (#{resource.identifier_str})\n")
        resource.data_files.each do |f|
          case f.file_state
          when 'created'
            logger.info(" -- created file moving to permanent store #{f.upload_file_name} -- #{f.s3_staged_path}")
            if f.url && !s3.exists?(s3_key: f.s3_staged_path)
              copy_external_to_permanent_store(f)
            else
              copy_to_permanent_store(f)
            end
          when 'copied'
            # Files aren't actually copied, we just reference the file from the previous version of the dataset
            logger.info(" -- copied file #{f.upload_file_name}")
          when 'deleted'
            # Files aren't actually deleted, we just don't migrate the file description to future versions of the dataset
            logger.info(" -- deleted file #{f.upload_file_name}")
          else
            message = "Unable to determine what to do with file #{f.upload_file_name}"
            logger.error(message)
            return Stash::Repo::SubmissionResult.failure(resource_id: resource_id, request_desc: description, error: StandardError.new(message))
          end
        end
        resource.save!
        Stash::Repo::SubmissionResult.success(resource_id: resource_id, request_desc: description, message: 'Success')
      end

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
        payment.update(pay_with_invoice: true, invoice_id: invoice.id) if invoice
      end

      def create_missing_invoice
        payment_service = PaymentsService.new(nil, resource, {})
        if payment_service.total_amount > 0
          Rails.logger.warn("No payment found for resource ID #{resource.id} as waiver that should pay LDF rate")
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

      def copy_to_permanent_store(data_file)
        staged_bucket = APP_CONFIG[:s3][:bucket]
        staged_key = data_file.s3_staged_path
        permanent_bucket = APP_CONFIG[:s3][:merritt_bucket]
        permanent_key = "v3/#{data_file.s3_staged_path}"
        logger.info("file #{data_file.id} #{staged_bucket}/#{staged_key} ==> #{permanent_bucket}/#{permanent_key}")

        # SKIP uploading the file again if
        #   it exists on permanent store
        #   it has the same size
        # in case a previous job uploaded the file but failed on generating checksum
        if !permanent_s3.exists?(s3_key: permanent_key) || !permanent_s3.size(s3_key: permanent_key) == data_file.upload_file_size
          logger.info("file copy #{data_file.id} ==> #{permanent_bucket}/#{permanent_key}")
          s3.copy(from_bucket_name: staged_bucket, from_s3_key: staged_key,
                  to_bucket_name: permanent_bucket, to_s3_key: permanent_key,
                  size: data_file.upload_file_size)
        else
          logger.info("file copy skipped #{data_file.id} ==> #{permanent_bucket}/#{permanent_key} already exists")
        end

        update = { storage_version_id: resource.id }
        if data_file.digest.nil?
          digest_type = 'sha-256'
          digest_input = s3.presigned_download_url(s3_key: staged_key)
          sums = Stash::Checksums.get_checksums([digest_type], digest_input)
          raise "Error generating file checksum (#{data_file.upload_file_name})" if sums.input_size != data_file.upload_file_size

          update[:digest_type] = digest_type
          update[:digest] = sums.get_checksum(digest_type)
          update[:validated_at] = Time.now.utc
        end
        data_file.update(update)
      end

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/MethodLength
      def copy_external_to_permanent_store(data_file)
        permanent_bucket = APP_CONFIG[:s3][:merritt_bucket]
        permanent_key = "v3/#{data_file.s3_staged_path}"
        s3_perm = Stash::Aws::S3.new(s3_bucket_name: permanent_bucket)
        chunk_size = get_chunk_size(data_file.upload_file_size)

        input_size = 0
        digest_type = 'sha-256'
        sums = Stash::Checksums.new([digest_type])
        algorithm = sums.get_algorithm(digest_type).new

        logger.info("file #{data_file.id} #{data_file.url} ==> #{permanent_bucket}/#{permanent_key}")
        s3_perm.object(s3_key: permanent_key).upload_stream(part_size: chunk_size, storage_class: 'INTELLIGENT_TIERING') do |write_stream|
          write_stream.binmode
          read_stream = Down.open(data_file.url, rewindable: false)
          chunk = read_stream.read(chunk_size)
          chunk_num = 1
          cycle_time = Time.now
          while chunk.present?
            write_stream << chunk
            input_size += chunk.length
            logger.info("file #{data_file.id} chunk #{chunk_num} size #{chunk.length} ==> #{input_size} (#{Time.now - cycle_time})")
            cycle_time = Time.now
            algorithm.update(chunk)
            chunk = read_stream.read(chunk_size)
            chunk_num += 1
          end
        end

        update = { storage_version_id: resource.id }

        if data_file.digest.nil?
          raise "Error generating file checksum (#{data_file.upload_file_name})" if input_size != data_file.upload_file_size

          update[:digest_type] = digest_type
          update[:digest] = algorithm.hexdigest
          update[:validated_at] = Time.now.utc
        end

        data_file.update(update)
      end

      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength

      def get_chunk_size(size)
        # AWS transfers allow up to 10,000 parts per multipart upload, with a minimum of 5MB per part.
        return 250 * 1024 * 1024 if size > 300_000_000_000
        return 30 * 1024 * 1024 if size > 100_000_000_000
        return 10 * 1024 * 1024 if size > 10_000_000_000

        5 * 1024 * 1024
      end

      def resource
        @resource ||= StashEngine::Resource.find(resource_id)
      end

      def s3
        @s3 ||= Stash::Aws::S3.new
      end

      def permanent_s3
        @permanent_s3 ||= Stash::Aws::S3.new(s3_bucket_name: APP_CONFIG[:s3][:merritt_bucket])
      end

      def id_helper
        @id_helper ||= Stash::Doi::DataciteGen.new(resource: resource)
      end

      def description_for(resource)
        "#{self.class} for resource #{resource_id} (#{resource.identifier_str}): posting update to storage"
      end

    end
  end
end
