require 'byebug'
require 'http'

# a significantly simplified class for dealing with Files instead of sending them through our server
# and redirects to a S3 presigned URL
module Stash
  module Download

    class S3CustomError < StandardError; end

    class VersionPresigned
      attr_reader :cc

      # passing the controller context allows us to do actions the controller would normally do such as redirecting
      # or rendering within the rails context
      def initialize(controller_context:, resource:)
        @cc = controller_context
        @resource = resource
        return if @resource.blank?

        @tenant = @resource&.tenant
        @version = @resource&.stash_version
      end

      def valid_resource?
        @resource.present? && @tenant.present? && @version.present?
      end

      def generate_token
        token = @resource.download_token
        token.token = SecureRandom.uuid if token.token.nil?
        token.available = Time.now.utc + (1 * 60)
        token.save
        token.token
      end

      # rubocop:disable Metrics/AbcSize
      def download(resource:)
        @resource ||= resource
        if @resource&.total_file_size&. < APP_CONFIG[:maximums][:api_zip_size]
          @resource.identifier.update_columns(downloaded_at: Time.now.utc)
          credentials = ::Aws::Credentials.new(APP_CONFIG[:s3][:key], APP_CONFIG[:s3][:secret])
          signer = ::Aws::Sigv4::Signer.new(service: 'lambda', region: APP_CONFIG[:s3][:region], credentials_provider: credentials)

          time = @resource.publication_date.present? && @resource.publication_date < Time.now.utc ? @resource.publication_date : @resource.updated_at

          zip_name = "#{"doi_#{resource.identifier_value}__v#{time.strftime('%Y%m%d')}".gsub(
            %r{\.|:|/}, '_'
          )}.zip"

          h = Rails.application.routes.url_helpers
          download_url = h.version_zip_assembly_url(@resource.id).gsub('http://localhost:3000', 'https://v3-dev.datadryad.org').gsub(/^http:/, 'https:')

          zip_url = signer.presign_url(
            http_method: 'GET',
            expires_in: 3600,
            url: "https://#{APP_CONFIG[:lambda_id][:dataZip]}.lambda-url.#{APP_CONFIG[:s3][:region]}.on.aws/?filename=#{zip_name}&download_url=#{CGI.escape("#{download_url}/#{generate_token}")}"
          )
          cc.redirect_to zip_url.to_s, allow_other_host: true
        else
          cc.render status: 405, plain: 'The dataset is too large for zip file generation. Please download each file individually.'
        end
      end
      # rubocop:enable Metrics/AbcSize
    end
  end
end
