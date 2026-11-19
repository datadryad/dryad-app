# frozen_string_literal: true

require 'csv'

module Invoices
  class Generate
    include ActionView::Helpers::NumberHelper

    attr_reader :commitment, :sponsor, :year, :csv

    def initialize(sponsor, year)
      @sponsor = sponsor
      @year = year
      @commitment = year_commitment
      @csv = []
    end

    def as_pdf
      raise 'Invalid sponsor' unless sponsor.present?

      summary = Invoices::Summary.new(commitment, sponsor, year).generate_pdf
      generate_identifiers_list(summary)
      true
    end

    private

    def year_commitment
      PaymentCommitment.where(year: year, payment_configuration_id: sponsor.payment_configuration.id).first
    end

    def generate_identifiers_list(summary)
      return if sponsor.blank?

      filename = "datasets_list_#{year}_submissions_#{StashEngine::GenericFile.sanitize_file_name(PayerDetailsService.new(sponsor).name)}_#{year}.pdf"
      file_path = File.join(REPORTS_DIR, filename)
      Rails.logger.info "Writing sponsor summary to #{filename}"

      template_path = Rails.root.join('app', 'views', 'payment_details', 'pdf_identifiers.html.erb')
      html_template = File.read(template_path)

      # Create an ERB template with the HTML
      erb_template = ERB.new(html_template)

      context = PdfTemplateContext.new
      context.instance_variable_set(:@sponsor, sponsor)
      context.instance_variable_set(:@identifiers, Payments::Sponsor.new(sponsor, year: year).identifiers)
      context.instance_variable_set(:@calculations, summary)
      rendered_html = erb_template.result(context.instance_eval { binding })

      pdf = Grover.new(rendered_html).to_pdf
      File.open(file_path, 'wb') do |file|
        file << pdf
      end
    end
  end
end
