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
        create_invoice(resource)
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

      def create_invoice(resource)
        payment = resource.payment

        # pp payment
        # pp payment.invoice_details
        author = StashEngine::Author.find(payment.invoice_details['author_id'])
        # pp author

        # fees = ResourceFeeCalculatorService.new(resource).calculate({generate_invoice: true})

        # aaaa
        invoicer = Stash::Payments::StripeInvoicer.new(resource)
        return if invoicer.invoice_created?

        customer_id = invoicer.lookup_prior_stripe_customer_id(payment.invoice_details['customer_email'])
        unless customer_id.present?
          customer_id = invoicer.create_customer(payment.invoice_details['customer_name'],
                                                 payment.invoice_details['customer_email']).id
        end
        author.update(stripe_customer_id: customer_id)

        invoice = invoicer.create_invoice
        payment.update(pay_with_invoice: true, invoice_id: invoice.id)
      end

      def copy_to_permanent_store(data_file)
        staged_bucket = APP_CONFIG[:s3][:bucket]
        staged_key = data_file.s3_staged_path
        permanent_bucket = APP_CONFIG[:s3][:merritt_bucket]
        permanent_key = "v3/#{data_file.s3_staged_path}"
        logger.info("file #{data_file.id} #{staged_bucket}/#{staged_key} ==> #{permanent_bucket}/#{permanent_key}")
        s3.copy(from_bucket_name: staged_bucket, from_s3_key: staged_key,
                to_bucket_name: permanent_bucket, to_s3_key: permanent_key,
                size: data_file.upload_file_size)
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
        s3_perm.object(s3_key: permanent_key).upload_stream(part_size: chunk_size) do |write_stream|
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

      def id_helper
        @id_helper ||= Stash::Doi::DataciteGen.new(resource: resource)
      end

      def description_for(resource)
        "#{self.class} for resource #{resource_id} (#{resource.identifier_str}): posting update to storage"
      end

    end
  end
end
