require 'byebug'
require 'http'

# a significantly simplified class for dealing with Files instead of sending them through our server
# and redirects to a S3 presigned URL
module Stash
  module Download

    class S3CustomError < StandardError; end

    class ZipVersionPresigned
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

      def download(resource:)
        @resource ||= resource
        if APP_CONFIG.maximums.zip_size > @resource&.total_file_size
          credentials = ::Aws::Credentials.new(APP_CONFIG[:s3][:key], APP_CONFIG[:s3][:secret])
          signer = ::Aws::Sigv4::Signer.new(service: 'lambda', region: APP_CONFIG[:s3][:region], credentials_provider: credentials)

          time = @resource.publication_date.present? && @resource.publication_date < Time.now.utc ? @resource.publication_date : @resource.updated_at

          zip_name = "#{"doi_#{resource.identifier_value}__v#{time.strftime('%Y%m%d')}".gsub(
            %r{\.|:|/}, '_'
          )}.zip"

          h = Rails.application.routes.url_helpers
          download_url = h.version_zip_assembly_url(@resource.id).gsub('http://localhost:3000', 'https://dryad-dev.cdlib.org').gsub(/^http:/, 'https:')

          zip_url = signer.presign_url(
            http_method: 'GET',
            expires_in: 3600,
            url: "https://#{APP_CONFIG[:s3][:lambda_id][:dataZip]}.lambda-url.#{APP_CONFIG[:s3][:region]}.on.aws/?filename=#{zip_name}&download_url=#{CGI.escape("#{download_url}/#{generate_token}")}"
          )
          cc.redirect_to zip_url.to_s
        else
          cc.render status: 405, plain: 'The dataset is too large for zip file generation. Please download each file individually.'
        end
      end

    end
  end
end
