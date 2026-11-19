# frozen_string_literal: true

require 'csv'

module Invoices
  class Generate
    include ActionView::Helpers::NumberHelper
    include Reports::BaseS3Report

    attr_reader :commitment, :sponsor, :year, :csv

    def initialize(sponsor, year)
      @sponsor = sponsor
      @year = year
      @commitment = year_commitment
      @csv = []
      filename = "#{StashEngine::GenericFile.sanitize_file_name(PayerDetailsService.new(sponsor).name)}_#{year}_invoice.pdf"
      @file_path = "#{Rails.env}/#{year}/#{filename}"
    end

    def as_pdf
      raise 'Invalid sponsor' unless sponsor.present?

      summary = Invoices::Summary.new(commitment, sponsor, year).generate_pdf
      pdf = generate_identifiers_list(summary)
      if upload_to_s3(pdf, @file_path, s3_bucket_name: APP_CONFIG.s3.invoices_bucket)
        inv = SponsorInvoice.find_or_initialize_by(sponsor: sponsor, year: year)
        return inv.update(s3_key: @file_path)
      end
      false
    end

    private

    def year_commitment
      PaymentCommitment.where(year: year, payment_configuration_id: sponsor.payment_configuration.id).first
    end

    def generate_identifiers_list(summary)
      return if sponsor.blank?

      template_path = Rails.root.join('app', 'views', 'payment_details', 'pdf_identifiers.html.erb')
      html_template = File.read(template_path)

      # Create an ERB template with the HTML
      erb_template = ERB.new(html_template)

      context = PdfTemplateContext.new
      context.instance_variable_set(:@sponsor, sponsor)
      context.instance_variable_set(:@identifiers, Payments::Sponsor.new(sponsor, year: year).identifiers)
      context.instance_variable_set(:@calculations, summary)
      rendered_html = erb_template.result(context.instance_eval { binding })

      Grover.new(rendered_html).to_pdf
    end
  end
end
