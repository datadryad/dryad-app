describe PaymentCommitmentService, type: :service do
  let(:sponsor) { create(:journal_organization) }
  let!(:payment_configuration) { create(:payment_configuration, partner: sponsor, payment_plan: '2025') }

  describe '#generate' do
    let(:service) { PaymentCommitmentService.new(sponsor) }

    context 'with valid parameters' do
      let(:commitment_years) { 3 }
      let(:asf) { 10_000 }
      let(:dpc_tier) { 2 }
      let(:covers_ldf) { true }
      let(:ldf) { 2000 }
      let(:asf_prepaid) { 500 }
      let(:start_date) { Date.new(2026, 1, 1) }
      let(:consortium_discount) { 10 }
      let(:ldf_size_limit) { 2 }
      let(:include_year_0) { false }

      it 'creates 3 payment commitments' do
        expect do
          service.generate(commitment_years, asf: asf, dpc_tier: dpc_tier, covers_ldf: covers_ldf, ldf: ldf, asf_prepaid: asf_prepaid,
                                             start_date: start_date, consortium_discount: consortium_discount, ldf_size_limit: ldf_size_limit,
                                             include_year_0: include_year_0)
        end.to change(PaymentCommitment, :count).by(3)

        payment_commitments = sponsor.commitments.order(year: :asc)
        commitment = payment_commitments.first
        expect(commitment.sponsor).to eq(sponsor)
        expect(commitment.commitment_years).to eq(commitment_years)
        expect(commitment.update_notes.to_a[0][1]).to eq('Create year 1 - 2026 of 3 years commitment')
        expect(commitment.year_index).to eq(1)
        expect(commitment.start_date).to eq(start_date)
        expect(commitment.year).to eq(2026)
        expect(commitment.payment_plan).to eq(sponsor.payment_configuration.payment_plan)
        expect(commitment.asf).to eq(asf)
        expect(commitment.period_discount).to eq(50)
        expect(commitment.consortium_discount).to eq(consortium_discount)
        expect(commitment.dpc_commitment_price).to eq(1650)
        expect(commitment.dpc_commitment).to eq(15)
        expect(commitment.dpc_carryover).to eq(0)
        expect(commitment.covers_ldf).to eq(covers_ldf)
        expect(commitment.ldf_commitment).to eq(ldf)
        expect(commitment.ldf_carryover).to eq(0)
        expect(commitment.ldf_size_limit).to eq(ldf_size_limit)
        expect(commitment.asf_prepaid).to eq(asf_prepaid)
        expect(commitment.batch).to be_present
        expect(commitment.asf_due).to eq(4500)
      end

      it 'has proper values for multi year' do
        service.generate(commitment_years, asf: asf, dpc_tier: dpc_tier, covers_ldf: covers_ldf, ldf: ldf, asf_prepaid: asf_prepaid,
                                           start_date: start_date, consortium_discount: consortium_discount, ldf_size_limit: ldf_size_limit,
                                           include_year_0: include_year_0)

        commitments = sponsor.commitments.order(year: :asc)
        expect(commitments.map(&:year)).to eq([2026, 2027, 2028])
        expect(commitments.map(&:year_index)).to eq([1, 2, 3])
        expect(commitments.map(&:period_discount)).to eq(COMMITMENT_DISCOUNTS['3'])
        expect(commitments.map(&:consortium_discount)).to eq([consortium_discount] * 3)
      end

      it 'creates one payment commitment for 1 year' do
        expect do
          service.generate(1, asf: asf, dpc_tier: dpc_tier, covers_ldf: covers_ldf, ldf: ldf, asf_prepaid: asf_prepaid, start_date: start_date,
                              consortium_discount: consortium_discount, ldf_size_limit: ldf_size_limit, include_year_0: include_year_0)
        end.to change(PaymentCommitment, :count).by(1)
      end
    end

    context 'with invalid parameters' do
      it 'returns error message for invalid commitment years' do
        expect(
          service.generate(2, asf: 100, dpc_tier: 1, covers_ldf: true, ldf: 200, asf_prepaid: 50, start_date: Date.new(2026, 1, 1),
                              consortium_discount: 10, ldf_size_limit: 1000, include_year_0: false)
        ).to eq('Invalid commitment years, must be 1 or 3')
      end

      it 'returns error message for invalid start date' do
        expect(service.generate(3, asf: 100, dpc_tier: 1, covers_ldf: true, ldf: 200, asf_prepaid: 50, start_date: '', consortium_discount: 10,
                                   ldf_size_limit: 1000, include_year_0: false)).to eq('Start date must be a valid date')
      end

      it 'returns error message for invalid ASF' do
        expect(service.generate(3, asf: '', dpc_tier: 1, covers_ldf: true, ldf: 200, asf_prepaid: 50, start_date: Date.new(2026, 1, 1),
                                   consortium_discount: 10, ldf_size_limit: 1000, include_year_0: false)).to eq('ASF must be a valid number')
      end

      it 'returns error message for invalid DPC tier' do
        expect(
          service.generate(3, asf: 100, dpc_tier: 0, covers_ldf: true, ldf: 200, asf_prepaid: 50, start_date: Date.new(2026, 1, 1),
                              consortium_discount: 10, ldf_size_limit: 1000, include_year_0: false)
        ).to eq('Data Publishing Charge tier is invalid')
      end

      it 'returns error message for invalid LDF size limit' do
        expect(
          service.generate(3, asf: 100, dpc_tier: 1, covers_ldf: true, ldf: 200, asf_prepaid: 50, start_date: Date.new(2026, 1, 1),
                              consortium_discount: 10, ldf_size_limit: '', include_year_0: false)
        ).to eq('Large Data Fee size limit is incorrect')
      end
    end
  end

  describe '#update' do
    let(:service) { PaymentCommitmentService.new(sponsor) }
    let!(:payment_commitment) { create(:payment_commitment, sponsor: sponsor, asf: 100, period_discount: 0, consortium_discount: 0) }

    context 'with valid parameters' do
      let(:update_params) do
        {
          asf: 10_000,
          period_discount: 10,
          consortium_discount: 5
        }
      end

      it 'updates the payment commitment' do
        updated_commitment = service.update(payment_commitment, update_params)
        updated_commitment.reload

        expect(updated_commitment.asf).to eq(10_000)
        expect(updated_commitment.period_discount).to eq(10)
        expect(updated_commitment.consortium_discount).to eq(5)
        expect(updated_commitment.asf_due).to eq(8550)
      end
    end

    context 'with invalid parameters' do
      let(:update_params) do
        {
          asf: '',
          period_discount: 'invalid',
          consortium_discount: 5
        }
      end

      it 'does not update the payment commitment' do
        service.update(payment_commitment, update_params)
        updated_commitment = PaymentCommitment.find(payment_commitment.id)

        expect(updated_commitment.asf).to be_nil
        expect(updated_commitment.period_discount).to be_zero
        expect(updated_commitment.consortium_discount).to eq(5)
        expect(updated_commitment.asf_due).to be_zero
      end
    end
  end
end
