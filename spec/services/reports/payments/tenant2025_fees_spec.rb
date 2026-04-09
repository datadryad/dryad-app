describe Reports::Payments::Tenant2025Fees do

  let(:args) { OpenStruct.new(sc_report: File.join('spec', 'fixtures', 'reports', 'shopping_cart_report_2025.csv')) }
  let!(:tenant_consortium) { create(:tenant, id: '2056-3744', short_name: 'consortium') }
  let!(:tenant1) { create(:tenant, id: 'member1', sponsor_id: '2056-3744', short_name: 'member1') }
  let!(:tenant2) { create(:tenant, id: 'member2', sponsor_id: '2056-3744', short_name: 'member2') }
  let!(:payment_configuration) { create(:payment_configuration, partner: tenant_consortium, payment_plan: '2025', covers_dpc: true) }

  let(:fake_pdf) { '%PDF-1.4 FAKE PDF CONTENT' }

  before do
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
      let(:report_path) { File.join('spec', 'fixtures', 'reports', '2025_2025_fees_tenant_summary.csv') }
      let(:report_headers) { %w[SponsorName InstitutionName Count] }

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

        it 'creates needed PDF summary files' do
          allow_any_instance_of(described_class).to receive(:write_sponsor_summary).twice
        end

        it 'has proper info' do
          report = CSV.parse(File.read(report_path))
          expect(report.count).to eq(4)
          expect(report[0]).to eq(report_headers)
          expect(report[1]).to eq(['consortium', 'consortium', '2', ''])
          expect(report[2]).to eq(['consortium', 'member1', '0', ''])
          expect(report[3]).to eq(['consortium', 'member2', '0', ''])
        end
      end
    end
  end
end
