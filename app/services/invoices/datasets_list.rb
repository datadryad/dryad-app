module Invoices
  class DatasetsList
    include StashEngine::ApplicationHelper
    include ActionView::Helpers::NumberHelper

    attr_reader :commitment, :sponsor, :year

    def initialize(payment_commitment, sponsor, year)
      @commitment = payment_commitment
      @sponsor = sponsor
      @year = year
    end

    def generate
      return if sponsor.blank?

      filename = "datasets_list_#{year}_submissions_#{StashEngine::GenericFile.sanitize_file_name(sponsor.long_name)}_#{year}.pdf"
      Rails.logger.info "Writing sponsor summary to #{filename}"

      template_path = Rails.root.join('app', 'views', 'payment_details', 'pdf_identifiers.html.erb')
      html_template = File.read(template_path)

      # Create an ERB template with the HTML
      erb_template = ERB.new(html_template)

      context = TemplateContext.new
      context.instance_variable_set(:@sponsor, sponsor)
      context.instance_variable_set(:@identifiers, Payments::Sponsor.new(sponsor, year: year).identifiers)
      rendered_html = erb_template.result(context.instance_eval { binding })

      pdf = Grover.new(rendered_html).to_pdf
      File.open(filename, 'wb') do |file|
        file << pdf
      end
    end

    def datasets_list
      Payments::Sponsor.new(sponsor, year: year).identifiers
    end

    # Write a PDF that Dryad can send to the sponsor, summarizing the datasets published
    # rubocop:disable Metrics/MethodLength
    def write_sponsor_summary(name:, report_period:, table:, payment_plan:)
      return if name.blank? || table.blank?

      filename = "datasets_list_#{year}_submissions_#{StashEngine::GenericFile.sanitize_file_name(name)}_#{report_period}.pdf"
      Rails.logger.info "Writing sponsor summary to #{filename}"
      table_content = ''
      table.each do |ident|
        res = ident.latest_resource
        sum = ident.sponsored_payment_logs.sum(:ldf)
        ldf = sum > 0 ? number_to_currency(sum) : ''

        table_content << <<-HTML
          <tr>
            <td>#{ident.identifier}</td>
            <td>#{res.title.html_safe}</td>
            <td>#{ident.resources.count}</td>
            <td>#{res.last_curation_activity.created_at.to_date}</td>
            <td>#{filesize res.total_file_size}</td>
            <td>#{ldf}</td>
          </tr>
        HTML
      end
      html_content = <<-HTML
        <head><style>
        tr:nth-child(even) {
            background-color: #f2f2f2;
        }
        th {
            background-color: #005581;
            color: white;
            text-align: left;
            padding: 10px;
        }
        td {
            padding: 10px;
        }
        </style></head>
        <h1>#{sponsor.long_name}</h1>
        <p>Dryad submissions accepted under a #{payment_plan} payment plan.<br/>
        Reporting period: #{report_period}<br/>
        Report generated on: #{Date.today}</p>
        <table>
          #{pdf_table_header}
          #{table_content}
        </table>
      HTML

      pdf = Grover.new(html_content).to_pdf
      File.open(filename, 'wb') do |file|
        file << pdf
      end
    end

    # rubocop:enable Metrics/MethodLength

    private

    def pdf_table_header
      <<-HTML
        <tr>
          <th width="15%">DOI</th>
          <th width="40%">Title</th>
          <th width="10%">Version count</th>
          <th width="20%">Publish Date</th>
          <th width="20%">Size</th>
          <th width="20%">Sponsored LDF</th>
        </tr>
      HTML
    end
  end
end
