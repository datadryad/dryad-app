describe PaymentCommitmentService, type: :service do
  let(:sponsor) { create(:journal_organization) }
  let!(:payment_configuration) { create(:payment_configuration, partner: sponsor, payment_plan: '2025') }

  describe '#generate' do
    let(:service) { PaymentCommitmentService.new(sponsor) }

    let(:commitment_years) { 3 }
    let(:asf) { 10_000 }
    let(:prepayment_carryover) { 0 }
    let(:dpc_tier) { 2 }
    let(:covers_ldf) { true }
    let(:ldf) { 2000 }
    let(:asf_prepaid) { 500 }
    let(:start_date) { Date.new(2026, 1, 1) }
    let(:consortium_discount) { 10 }
    let(:ldf_size_limit) { 2 }
    let(:include_year_0) { false }

    let(:options) do
      {
        asf: asf, dpc_tier: dpc_tier, covers_ldf: covers_ldf, ldf: ldf, asf_prepaid: asf_prepaid,
        start_date: start_date, consortium_discount: consortium_discount, ldf_size_limit: ldf_size_limit,
        include_year_0: include_year_0, prepayment_carryover: prepayment_carryover
      }
    end

    context 'with valid parameters' do
      it 'creates 3 payment commitments' do
        expect do
          service.generate(commitment_years, options)
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

      context 'with 3 years commitment' do
        before { service.generate(commitment_years, options) }
        it 'has proper values for multi year' do
          commitments = sponsor.commitments.order(year: :asc)
          expect(commitments.map(&:year)).to eq([2026, 2027, 2028])
          expect(commitments.map(&:year_index)).to eq([1, 2, 3])
          expect(commitments.map(&:period_discount)).to eq(COMMITMENT_DISCOUNTS['3'])
          expect(commitments.map(&:consortium_discount)).to eq([consortium_discount] * 3)
        end

        context 'with prepayment carryover' do
          let(:prepayment_carryover) { 1000 }

          it 'only sets prepayment on first year' do
            commitments = sponsor.commitments.order(year: :asc)
            expect(commitments.map(&:prepayment_carryover)).to eq([1000, 0, 0])
          end
        end

        context 'with year 0 true' do
          let(:include_year_0) { true }

          it 'creates 4 entries' do
            expect(sponsor.commitments.count).to eq(4)
          end
        end
      end

      context 'with 1 year commitment' do
        let(:commitment_years) { 1 }

        it 'creates one payment commitment for 1 year' do
          expect do
            service.generate(commitment_years, options)
          end.to change(PaymentCommitment, :count).by(1)
        end

        context 'with year 0 true' do
          let(:include_year_0) { true }
          before { service.generate(commitment_years, options) }

          it 'creates 2 entries' do
            expect(sponsor.commitments.count).to eq(2)
          end

          context 'with prepayment carryover' do
            let(:prepayment_carryover) { 1000 }

            it 'only sets prepayment on first year' do
              commitments = sponsor.commitments.order(year: :asc)
              expect(commitments.map(&:prepayment_carryover)).to eq([1000, 0])
            end
          end
        end
      end
    end

    context 'with invalid parameters' do
      context 'with invalid parameters' do
        let(:commitment_years) { 2 }

        it 'returns error message for invalid commitment years' do
          expect(service.generate(commitment_years, options)).to eq('Invalid commitment years, must be 1 or 3')
        end
      end

      context 'with invalid start date' do
        let(:start_date) { '' }

        it 'returns error message for invalid commitment years' do
          expect(service.generate(commitment_years, options)).to eq('Start date must be a valid date')
        end
      end

      context 'with invalid DPC tier' do
        let(:dpc_tier) { 0 }

        it 'returns error message for invalid commitment years' do
          expect(service.generate(commitment_years, options)).to eq('Data Publishing Charge tier is invalid')
        end
      end

      context 'with invalid asf' do
        let(:asf) { '' }

        it 'returns error message for invalid commitment years' do
          expect(service.generate(commitment_years, options)).to eq('ASF must be a valid number')
        end
      end

      context 'with invalid LDF size limit' do
        let(:ldf_size_limit) { '' }

        it 'returns error message for invalid commitment years' do
          expect(service.generate(commitment_years, options)).to eq('Large Data Fee size limit is incorrect')
        end
      end
    end
  end

  describe '#update' do
    let(:service) { PaymentCommitmentService.new(sponsor) }
    let!(:payment_commitment) do
      create(:payment_commitment, sponsor: sponsor, asf: 100, period_discount: 0, consortium_discount: 0, dpc_commitment_price: 2700)
    end

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
