require 'uri'

# A job that loads metadata for a single record.
class Dash2::Harvester::OAIRecordLoader < ActiveJob::Base

  ############################################################
  # Attributes

  attr_reader :oai_repository_uri
  attr_reader :oai_record_id

  ############################################################
  # Initializer

  # TODO this is wrong -- job classes need to be stateless & thread-safe

  # Creates a new record-loading job for the specified repository and record.
  #
  # @param oai_repository_url [String] the base URL of the target repository
  # @param oai_record_id [String] the OAI identifier of the target record
  # @raise [URI::InvalidURIError] if +oai_repository_url+ is invalid (note that
  #   we do *not* check that the OAI identifier is a valid URI; we'll let the OAI
  #   provider reject it, if it cares)
  def initialize(oai_repository_url, oai_record_id)
    @oai_repository_uri = URI.parse oai_repository_url
    @oai_record_id = oai_record_id
  end

  ############################################################
  # ActiveJob implementation

  # Queues this record-loading job for execution, passing the result
  # to the specified +on_success+ lambda when the record is loaded
  # successfully, or, in the event of an exception, passing the result
  # to the specified +on_failure+ lambda.
  #
  # @param oai_repository_url [String] the base URL of the target repository
  # @param on_success [-> (String)] A lambda that will be passed the record
  #   data, if it's loaded successfully
  # @param on_failure [-> (Exception)] A lambda that will be passed any
  #   exception, if there is one
  def perform(on_success, on_failure)
    begin
      result = nil
      on_success.call(result)
    rescue => exception
      on_failure.call(exception)
    end
  end

  ############################################################
  # Private methods

  # TODO does this need to be tested directly?
  private
  def oai_client
    @oai_client ||= OAI::Client.new @oai_repository_url
  end

  private
  def oai_repository_url
    @oai_repository_url ||= @oai_repository_uri.to_s
  end

  def process_data(result) end
  def handle_failure(t) end

  some_data_source = ""
  loader = OAIRecordLoader.perform_later(some_data_source, method(:process_data), method(:handle_failure))

end
