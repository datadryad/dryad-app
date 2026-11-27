require 'rails_helper'

RSpec.describe Invoices::Calculations, type: :service do
  subject(:service) { described_class.new(commitment, sponsor, year) }

  let(:year) { 2026 }
  let(:covers_ldf) { true }
  let(:sponsor) { create(:journal_organization) }
  let!(:payment_configuration) { create(:payment_configuration, partner: sponsor, payment_plan: '2025') }
  let(:payments_sponsor) do
    instance_double(Payments::Sponsor, invoice_identifiers: double('relation', count: 10), spent_ldf: 1000)
  end

  let!(:commitment) do
    create(:payment_commitment,
           sponsor: sponsor, year: year, year_index: 1, batch: 'Batch1',
           asf: 20_000, asf_prepaid: 30_000, asf_due: 8_500,
           period_discount: 50, consortium_discount: 15,
           dpc_tier: 2, dpc_commitment: 15, dpc_commitment_price: 1_650, dpc_carryover: 0,
           covers_ldf: covers_ldf, ldf_commitment: 5_180, ldf_carryover: 0)
  end
  let!(:next_year_commitment) do
    create(:payment_commitment,
           sponsor: sponsor, year: year + 1, year_index: 2, batch: 'Batch1',
           asf: 20_000, asf_prepaid: 30_000, asf_due: 12_750,
           period_discount: 25, consortium_discount: 15,
           dpc_tier: 2, dpc_commitment: 15, dpc_commitment_price: 1_650, dpc_carryover: 0,
           covers_ldf: covers_ldf, ldf_commitment: 5_180, ldf_carryover: 0)
  end

  before do
    allow(Payments::Sponsor).to receive(:new).and_return(payments_sponsor)
  end

  def find_row(rows, label)
    rows.find { |row| row.first == label }
  end

  describe '#initialize' do
    it 'sets the commitment, sponsor, and year' do
      expect(service.commitment).to eq(commitment)
      expect(service.sponsor).to eq(sponsor)
      expect(service.year).to eq(year)
    end

    it 'initializes the result as an empty array' do
      expect(service.result).to eq([])
    end

    it 'reads the dpc and ldf coverage from the payment configuration' do
      expect(service.instance_variable_get(:@covers_dpc)).to be(true)
      expect(service.instance_variable_get(:@covers_ldf)).to be(true)
    end

    context 'when the sponsor has no payment configuration' do
      let(:sponsor) { create(:journal_organization) }
      let(:payment_configuration) { nil }

      it 'leaves the coverage flags nil' do
        expect(service.instance_variable_get(:@covers_dpc)).to be_nil
        expect(service.instance_variable_get(:@covers_ldf)).to be_nil
      end
    end
  end

  describe '#generate' do
    context 'when the sponsor is blank' do
      let(:sponsor) { nil }
      let(:commitment) { nil }
      let(:next_year_commitment) { nil }

      it 'raises an invalid sponsor error' do
        expect { service.generate }.to raise_error('Invalid sponsor')
      end
    end

    context 'when the commitment is not present' do
      let(:commitment) { nil }

      it 'raises a not configured error' do
        expect { service.generate }.to raise_error('Sponsor contract is not configured')
      end
    end

    context 'when the asf paid does not match the discounted asf' do
      let!(:commitment) do
        create(:payment_commitment,
               sponsor: sponsor, year: year, year_index: 1, batch: 'Batch1',
               asf: 20_000, asf_prepaid: 30_000, asf_due: 1_000,
               period_discount: 50, consortium_discount: 15,
               dpc_tier: 2, dpc_commitment: 15, dpc_commitment_price: 1_650, dpc_carryover: 0,
               covers_ldf: true, ldf_commitment: 5_180, ldf_carryover: 0)
      end

      it 'raises an error' do
        expect { service.generate }.to raise_error('Annual service fee Paid do not match')
      end
    end

    context 'with a valid commitment' do
      subject(:result) { service.generate }

      it 'returns the result rows and the current invoice total' do
        rows, total = result
        expect(rows).to be_an(Array)
        expect(total).to eq(15_330)
      end

      it 'adds the contract details' do
        rows, = result
        expect(rows).to include(['', 'Year 1', 'Year 2'])
        expect(rows).to include(['Year', 2026, 2027])
        expect(rows).to include(['Annual Service Fee', '$20,000', '$20,000'])
        expect(rows).to include(['Discount - 1 year', '50.0%', '25.0%'])
        expect(rows).to include(['Discount - Consortium', '15.0%', '15.0%'])
        expect(rows).to include(['Annual Service Fee Due', '$8,500', '$12,750'])
        expect(rows).to include(['Prepaid (Flexible)', '$30,000', '$30,000'])
      end

      it 'adds the prepayment summary' do
        rows, = result
        expect(find_row(rows, 'Beginning of Year Prepaid Balance')).to eq(['Beginning of Year Prepaid Balance', '$30,000'])
        expect(find_row(rows, 'Prepay Consumed at Invoiced')).to eq(['Prepay Consumed at Invoiced', '$15,330'])
        expect(find_row(rows, 'Prepaid Balance After Invoice')).to eq(['Prepaid Balance After Invoice', '$14,670'])
      end

      it 'adds the current year invoice summary' do
        rows, = result
        expect(rows).to include(['2026 Invoice Summary:', ''])
        expect(rows).to include(['Annual Service Fee', '$20,000'])
        expect(rows).to include(['Discount (Year 1)', '-$10,000'])
        expect(rows).to include(['Annual Service Fee Subtotal', '$10,000'])
        expect(rows).to include(['Discount (Consortium)', '-$1,500'])
        expect(rows).to include(['Annual Service Fee Paid', '$8,500'])
        expect(rows).to include(['Data Publishing Charge Paid', '$1,650'])
        expect(rows).to include(['Large Data Paid', '$5,180'])
        expect(rows).to include(['Additional Prepayment', '$30,000'])
        expect(rows).to include(['Total Due for CY26', '$15,330'])
        expect(rows).to include(['Prepay Carryover Used', '$15,330'])
        expect(rows).to include(['Total Paid', '$0'])
        expect(rows).to include(['Prepay Balance Remaining for Future Use', '$14,670'])
      end

      it 'adds the dpc year usage' do
        rows, = result
        expect(rows).to include(['2026 Usage Summary:', ''])
        expect(find_row(rows, 'Total DPC Available to use in 2026')).to eq(['Total DPC Available to use in 2026', 15])
        expect(find_row(rows, 'DPC Commitment Paid in 2026')).to eq(['DPC Commitment Paid in 2026', 15])
        expect(find_row(rows, 'DPC Carryover from Previous Year')).to eq(['DPC Carryover from Previous Year', 0])
        expect(find_row(rows, 'Total DPC Consumed in 2026')).to eq(['Total DPC Consumed in 2026', 10])
        expect(find_row(rows,
                        'Total DPC Remaining for Carryover to 2027 (Overage)')).to eq(['Total DPC Remaining for Carryover to 2027 (Overage)', 5])
        expect(find_row(rows, 'DPC Charge (only applies for overage)')).to eq(['DPC Charge (only applies for overage)', '$0'])
      end

      it 'adds the ldf year usage' do
        rows, = result
        expect(find_row(rows, 'Large Data Available to use in 2026')).to eq(['Large Data Available to use in 2026', '$5,180'])
        expect(find_row(rows, 'Large Data Commitment in 2026')).to eq(['Large Data Commitment in 2026', '$5,180'])
        expect(find_row(rows, 'Large Data Carryover from Previous Year')).to eq(['Large Data Carryover from Previous Year', '$0'])
        expect(find_row(rows, 'Total Large Data Consumed')).to eq(['Total Large Data Consumed', '$1,000'])
        expect(find_row(rows,
                        'Total Large Data Remaining for Carryover to 2027')).to eq(['Total Large Data Remaining for Carryover to 2027', '$4,180'])
      end

      it 'adds the next year invoice summary' do
        rows, = result
        expect(rows).to include(['2027 Invoice Summary:', ''])
        expect(rows).to include(['Annual Service Fee Due', '$12,750'])
        expect(rows).to include(['2027 Data Publishing Charge (# of datasets)', 15])
        expect(rows).to include(['2026 Data Publishing Charge Carryover Credit (Due)', 5])
        expect(rows).to include(['Total Data Publishing Charge Available in 2027', 20])
        expect(rows).to include(['Data Publishing Charge - Amount due', '$1,650'])
        expect(rows).to include(['2027 Large Data Fee - Invoice Amount', '$5,180'])
        expect(rows).to include(['2026 Large Data Fee - Carryover Credit (Due)', '$4,180'])
      end

      it 'adds the invoice totals' do
        rows, = result
        expect(find_row(rows, '2027 Amount Due')).to eq(['2027 Amount Due', '$19,580'])
        expect(find_row(rows, 'Prepayment Credit Applied')).to eq(['Prepayment Credit Applied', '$14,670'])
        expect(find_row(rows, '2027 Amount Invoiced')).to eq(['2027 Amount Invoiced', '$4,910'])
      end

      it 'adds the following year summary' do
        rows, = result
        expect(find_row(rows, 'Prepayment Remaining for 2028')).to eq(['Prepayment Remaining for 2028', '$0'])
      end
    end

    context 'when dpc is over the commitment' do
      let(:payments_sponsor) do
        instance_double(Payments::Sponsor, invoice_identifiers: double('relation', count: 20), spent_ldf: 1000)
      end

      it 'charges the overage and adds it to the next invoice' do
        rows, total = service.generate
        expect(find_row(rows, 'Total DPC Additional amount due for 2027 (Overage)')).to eq(['Total DPC Additional amount due for 2027 (Overage)', -5])
        expect(find_row(rows, 'DPC Charge (only applies for overage)')).to eq(['DPC Charge (only applies for overage)', '-$625'])
        expect(total).to eq(15_330)
      end
    end

    context 'when the sponsor does not cover dpc' do
      let!(:payment_configuration) { create(:payment_configuration, partner: sponsor, payment_plan: nil) }

      it 'omits the dpc usage and next year dpc rows' do
        rows, = service.generate
        expect(rows).not_to include(['2026 Usage Summary:', ''])
        expect(rows).not_to include(['2027 Data Publishing Charge (# of datasets)', 15])
      end
    end

    context 'when the sponsor does not cover ldf' do
      let(:covers_ldf) { false }

      it 'omits the ldf usage and next year ldf rows' do
        rows, = service.generate
        expect(rows).not_to include(['Large Data Available to use in 2026', '$5,180'])
        expect(rows).not_to include(['2027 Large Data Fee - Invoice Amount', '$5,180'])
      end
    end

    context 'when there is no next year commitment' do
      before do
        PaymentCommitment.where(year: year + 1, sponsor: sponsor).destroy_all
      end

      it 'omits the next year summary and invoice totals' do
        rows, = service.generate
        expect(rows).not_to include(['2027 Invoice Summary:', ''])
        expect(rows).not_to include(['2027 Amount Due', '$19,580'])
      end
    end
  end
end
