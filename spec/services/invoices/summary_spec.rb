require 'rails_helper'

RSpec.describe Invoices::Summary, type: :service do
  let(:invoice_data) do
    [
      ['Date', 'Amount', 'Status'],
      ['2026-11-01', '$100.00', 'Paid'],
      ['2026-11-02', '$200.00', 'Pending'],
      ['2026-11-03', '$150.00', 'Paid'],
      ['']
    ]
  end

  subject { described_class.new(invoice_data) }

  describe '#initialize' do
    it 'sets the data attribute' do
      expect(subject.data).to eq(invoice_data)
    end

    it 'initializes the csv attribute as an empty array' do
      expect(subject.csv).to be_an Array
      expect(subject.csv).to be_empty
    end

    it 'initializes the html attribute as an empty string' do
      expect(subject.html).to be_a String
      expect(subject.html).to be_empty
    end
  end

  describe '#generate_csv' do
    it 'returns CSV content as a string' do
      csv_content = subject.generate_csv
      expect(csv_content).to be_a String
      expect(csv_content).to include('Date,Amount,Status')
      expect(csv_content).to include('2026-11-01,$100.00,Paid')
    end
  end

  describe '#generate_pdf' do
    it 'generates the HTML content for the PDF' do
      html_content = subject.generate_pdf
      expect(html_content).to include('<table border="1" width="100%">')
      expect(html_content).to include(
        '<tr><th style="text-align: left">Date</th>' \
        '<td style="text-align: right; width: 80px">Amount</td>' \
        '<td style="text-align: right; width: 80px">Status</td></tr>'
      )
      expect(html_content).to include(
        '<tr><td style="text-align: left">2026-11-01</td>' \
        '<td style="text-align: right; width: 80px">$100.00</td>' \
        '<td style="text-align: right; width: 80px">Paid</td></tr>'
      )
      expect(html_content).to include(
        '<tr><td style="text-align: left">2026-11-02</td>' \
        '<td style="text-align: right; width: 80px">$200.00</td>' \
        '<td style="text-align: right; width: 80px">Pending</td></tr>'
      )
      expect(html_content).to include(
        '<tr><td style="text-align: left">2026-11-03</td>' \
        '<td style="text-align: right; width: 80px">$150.00</td>' \
        '<td style="text-align: right; width: 80px">Paid</td></tr>'
      )
    end
  end
end
