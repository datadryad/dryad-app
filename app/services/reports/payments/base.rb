module Reports
  module Payments
    class Base

      def call(args)
        sc_report_file = args.sc_report
        log "Producing 2025 fees tenant reports for #{sc_report_file}"

        md = /(.*)shopping_cart_report_(.*).csv/.match(sc_report_file)
        time_period = nil
        prefix = ''
        summary_filename = @summary_file_name
        if md.present? && md.size > 1
          prefix = md[1]
          time_period = md[2]
          summary_filename = "#{md[1]}#{time_period}_#{@summary_file_name}.csv"
        end

        log "Writing summary report to #{summary_filename}"
        build_csv_file(time_period: time_period, prefix: prefix, filename: summary_filename, sc_report_file: sc_report_file)
      end

      # Write a PDF that Dryad can send to the sponsor, summarizing the datasets published
      # rubocop:disable Metrics/MethodLength
      def write_sponsor_summary(name:, file_prefix:, report_period:, table:, payment_plan:)
        return if name.blank? || table.blank?

        filename = "#{file_prefix}#{payment_plan}_submissions_#{StashEngine::GenericFile.sanitize_file_name(name)}_#{report_period}.pdf"
        log "Writing sponsor summary to #{filename}"
        table_content = ''
        table.each do |row|
          table_content << "<tr><td>#{row[0]}</td><td>#{row[1]}</td><td>#{row[2]}</td></tr>"
        end
        html_content = <<-HTMLEND
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
          <h1>#{name}</h1>
          <p>Dryad submissions accepted under a #{payment_plan} payment plan.<br/>
          Reporting period: #{report_period}<br/>
          Report generated on: #{Date.today}</p>
          <table>
           <tr><th width="25%">DOI</th>
               <th width="55%">Journal Name</th>
               <th width="20%">Approval Date</th></tr>
           #{table_content}
          </table>
        HTMLEND

        pdf = Grover.new(html_content).to_pdf
        File.open(filename, 'wb') do |file|
          file << pdf
        end
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
