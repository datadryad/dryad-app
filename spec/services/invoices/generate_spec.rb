describe Invoices::Generate, type: :service do
  include Mocks::Aws

  subject(:service) { described_class.new(sponsor, year) }

  let(:year) { 2026 }
  let(:sponsor) { create(:tenant, long_name: 'Example Sponsor') }
  let!(:commitment) do
    create(:payment_commitment,
           sponsor: sponsor, year: year,
           asf: 20_000, asf_prepaid: 30_000, asf_due: 8_500,
           covers_ldf: true, ldf_commitment: 5_180, ldf_carryover: 0,
           dpc_tier: 2, dpc_commitment: 15, dpc_commitment_price: 1_650, dpc_carryover: 0,
           period_discount: 50, consortium_discount: 15)
  end
  let!(:next_year_commitment) do
    create(:payment_commitment,
           sponsor: sponsor, year: year + 1,
           asf: 20_000, asf_prepaid: 30_000, asf_due: 12_750,
           covers_ldf: true, ldf_commitment: 5_180, ldf_carryover: 0,
           dpc_tier: 2, dpc_commitment: 15, dpc_commitment_price: 1_650, dpc_carryover: 0,
           period_discount: 25, consortium_discount: 15)
  end
  let!(:payer_details) { instance_double(PayerDetailsService, name: 'Example Sponsor') }
  let(:file_path) { "#{Rails.env}/#{year}/Example_Sponsor_2026_invoice.pdf" }
  before do
    mock_aws!
  end

  describe '#initialize' do
    it 'sets the sponsor, year, commitment, and empty csv' do
      expect(service.sponsor).to eq(sponsor)
      expect(service.year).to eq(year)
      expect(service.commitment).to eq(commitment)
      expect(service.csv).to eq([])
    end

    it 'sets the invoice file path for the current environment and year' do
      expect(service.instance_variable_get(:@file_path)).to eq(file_path)
    end
  end

  describe '#as_pdf' do
    let(:invoice_data) { [['Date', 'Amount'], ['2026-11-01', '$100.00']] }
    let(:summary_html) { '<table>invoice summary</table>' }
    let(:pdf) { 'fake pdf bytes' }
    let(:calculations) { instance_double(Invoices::Calculations, generate: [invoice_data, 100.0]) }
    let(:summary) { instance_double(Invoices::Summary, generate_pdf: summary_html) }

    before do
      allow(Invoices::Calculations).to receive(:new).with(commitment, sponsor, year).and_return(calculations)
      allow(Invoices::Summary).to receive(:new).with(invoice_data).and_return(summary)
      allow(service).to receive(:generate_identifiers_list).with(summary_html).and_return(pdf)
    end

    it 'generates and writes the invoice PDF to S3' do
      expect(service).to receive(:upload_to_s3).with(pdf, file_path, s3_bucket_name: APP_CONFIG.s3.invoices_bucket).and_return(true)
      expect { service.as_pdf }.to change { SponsorInvoice.count }.by(1)
    end

    it 'updates the record when called twice with same year' do
      expect { service.as_pdf }.to change { SponsorInvoice.count }.by(1)
      expect { service.as_pdf }.to change { SponsorInvoice.count }.by(0)
    end

    context 'when the sponsor is blank' do
      before do
        allow(sponsor).to receive(:present?).and_return(false)
      end

      it 'raises an invalid sponsor error' do
        expect { service.as_pdf }.to raise_error('Invalid sponsor')
      end
    end
  end

  describe '#generate_identifiers_list' do
    let(:summary_html) { '<table>invoice summary</table>' }
    let(:template_html) { '<html><body><%= @calculations %></body></html>' }
    let(:rendered_html) { '<html><body>invoice summary</body></html>' }
    let(:template) { instance_double(ERB, result: rendered_html) }
    let(:pdf) { 'fake pdf bytes' }
    let(:grover) { instance_double(Grover, to_pdf: pdf) }
    let(:context) { PdfTemplateContext.new }

    before do
      allow(File).to receive(:read).with(Rails.root.join('app', 'views', 'payment_details', 'pdf_identifiers.html.erb'))
        .and_return(template_html)
      allow(ERB).to receive(:new).with(template_html).and_return(template)
      allow(PdfTemplateContext).to receive(:new).and_return(context)
      allow(StashEngine::Identifier).to receive(:none).and_return([])
      allow(Grover).to receive(:new).with(rendered_html).and_return(grover)
    end

    it 'renders the PDF template and returns Grover PDF output' do
      expect(service.send(:generate_identifiers_list, summary_html)).to eq(pdf)
      expect(context.instance_variable_get(:@sponsor)).to eq(sponsor)
      expect(context.instance_variable_get(:@identifiers)).to eq([])
      expect(context.instance_variable_get(:@calculations)).to eq(summary_html)
    end

    context 'when the sponsor is blank' do
      before do
        allow(sponsor).to receive(:blank?).and_return(true)
      end

      it 'returns nil without reading or rendering the template' do
        expect(File).not_to receive(:read)
        expect(service.send(:generate_identifiers_list, summary_html)).to be_nil
      end
    end
  end
end
