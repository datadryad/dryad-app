require 'byebug'
require 'csv'

module Reports
  module Payments
    class Base2025Fees < Reports::Payments::Base

      private

      def pdf_table_header
        <<-HTML
          <tr>
            <th width="25%">DOI</th>
            <th width="45%">Journal Name</th>
            <th width="15%">Size</th>
            <th width="15%">Approval Date</th>
          </tr>
        HTML
      end
    end
  end
end
