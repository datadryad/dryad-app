describe Reports::Payments::Journal2025Fees do

  let(:args) { OpenStruct.new(sc_report: File.join('spec', 'fixtures', 'reports', 'shopping_cart_report_2025.csv')) }
  let(:journal_org) { create(:journal_organization) }
  let!(:journal1) { create(:journal, sponsor: journal_org) }
  let!(:journal_issn1) { create(:journal_issn, journal: journal1, id: '1111-2222') }
  let!(:payment_configuration1) { create(:payment_configuration, partner: journal1, payment_plan: '2025', covers_dpc: true) }

  let!(:journal2) { create(:journal, sponsor: journal_org) }
  let!(:journal_issn2) { create(:journal_issn, journal: journal2, id: '1111-3333') }
  let!(:payment_configuration2) { create(:payment_configuration, partner: journal2, payment_plan: '2025', covers_dpc: true) }

  let!(:journal3) { create(:journal, sponsor: journal_org) }
  let!(:journal_issn3) { create(:journal_issn, journal: journal3, id: '1111-4444') }
  let!(:payment_configuration3) { create(:payment_configuration, partner: journal3, payment_plan: 'TIERED', covers_dpc: true) }

  let(:fake_pdf) { '%PDF-1.4 FAKE PDF CONTENT' }

  before do
    journal1.issns = [journal_issn1]
    journal2.issns = [journal_issn2]

    # Stub Grover
    grover_double = instance_double(Grover, to_pdf: fake_pdf)
    allow(Grover).to receive(:new).and_return(grover_double)
  end

  describe '#call' do
    it 'does not fails' do
      allow_any_instance_of(described_class).to receive(:write_sponsor_summary)
      expect { described_class.new.call(args).count }.not_to raise_error
    end

    context 'generated report file' do
      let(:report_path) { File.join('spec', 'fixtures', 'reports', '2025_2025_fees_summary.csv') }
      let(:report_headers) { %w[SponsorName JournalName Count] }

      context 'csv contents' do
        before do
          allow_any_instance_of(described_class).to receive(:write_sponsor_summary)
          described_class.new.call(args).count
        end
        after do
          FileUtils.rm_f(report_path)
        end

        it 'creates proper file' do
          expect(File.exist?(report_path)).to be_truthy
        end

        it 'has proper info' do
          report = CSV.parse(File.read(report_path))
          expect(report.count).to eq(3)
          expect(report[0]).to eq(report_headers)
          expect(report[1]).to eq([journal_org.name, journal1.title, '3', ''])
          expect(report[2]).to eq([journal_org.name, journal2.title, '1', ''])
        end
      end

      context 'pdf contents' do
        it 'creates needed PDF summary files' do
          allow(File).to receive(:open).and_return(StringIO.new)

          described_class.new.call(args).count

          expect(File).to have_received(:open).with('spec/fixtures/reports/2025_2025_fees_summary.csv', 'w', anything).once
          expect(File).to have_received(:open).with(
            "spec/fixtures/reports/2025_submissions_#{StashEngine::GenericFile.sanitize_file_name(journal_org.name)}_2025.pdf", 'wb'
          ).once
        end
      end
    end
  end
end
