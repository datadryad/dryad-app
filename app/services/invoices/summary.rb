require 'csv'
require 'stringio'

module Invoices
  class Summary
    include ActionView::Helpers::NumberHelper

    attr_reader :data, :csv, :html

    def initialize(invoice_data)
      @data = invoice_data
      @csv = []
      @html = ''
    end

    def generate_csv
      csv_output = StringIO.new
      CSV.open(csv_output, 'w') do |csv_instance|
        data.each do |row|
          csv_instance << row
        end
      end
      csv_output.string
    end

    def generate_pdf
      table_opened = false
      data.each do |row|
        # if empty row
        if row.size == 1 && row.first.blank?
          # if table is opened
          if table_opened
            @html += '</tbody></table>'
            table_opened = false
          end
          @html += '<br />'
        else
          @html += '<table border="1" width="100%"><thead>' unless table_opened
          add_row_to_table(row, as_header: !table_opened)
          table_opened = true
        end
      end
      html
    end

    private

    def add_row_to_table(row, as_header: false)
      @html += '<tr>'
      @html += cell(row.first, th: as_header, no_width: true)
      @html += row[1..].map { |item| cell(item) }.join
      @html += '</tr>'
    end

    def cell(value, th: false, no_width: false)
      tag = th ? :th : :td
      style = no_width ? 'text-align: left' : 'text-align: right; width: 80px'
      ActionController::Base.helpers.content_tag tag, value, style: style
    end
  end
end
