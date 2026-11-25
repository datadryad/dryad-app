describe PaymentCommitmentsController, type: :request do
  let(:user) { create(:user, role: 'superuser', tenant_id: 'dryad') }
  let(:sponsor) { create(:journal_organization) }
  let!(:payment_configuration) { create(:payment_configuration, partner: sponsor) }

  before do
    allow_any_instance_of(PaymentCommitmentsController).to receive(:session).and_return({ user_id: user.id }.to_ostruct)
  end

  describe 'GET #index' do
    before do
      get payment_commitments_path(type: 'publisher', sponsor_id: sponsor.id)
    end

    it 'returns a successful response' do
      expect(response).to have_http_status(200)
    end

    it 'assigns @sponsor_details' do
      expect(controller.instance_variable_get(:@sponsor_details)).to be_present
    end
  end

  describe 'GET #new' do
    it 'returns a successful response' do
      get new_payment_commitment_path(type: 'publisher', sponsor_id: sponsor.id), xhr: true

      expect(response).to have_http_status(200)
    end
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      let(:valid_params) do
        {
          commitment_years: 3,
          start_date: '2026-01-01',
          include_year_0: 'false',
          asf: '25.0',
          consortium_discount: '5.0',
          dpc_tier: 1,
          covers_ldf: '1',
          ldf_size_limit: 100,
          ldf_commitment: 200,
          asf_prepaid: 75.0
        }
      end

      it 'creates payment commitments' do
        expect do
          post payment_commitments_path(type: 'publisher', sponsor_id: sponsor.id), xhr: true, params: valid_params
        end.to change(PaymentCommitment, :count).by(3)

        expect(response).to be_successful
        expect(flash.now[:alert]).to be_nil
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        {
          commitment_years: 2,
          start_date: '',
          include_year_0: 'false'
        }
      end

      it 'does not create payment commitments' do
        expect do
          post payment_commitments_path(type: 'publisher', sponsor_id: sponsor.id), params: invalid_params
        end.to_not change(PaymentCommitment, :count)

        expect(response).not_to be_successful
        expect(flash.now[:alert]).to eq('Invalid commitment years, must be 1 or 3')
      end
    end
  end

  describe 'GET #edit' do
    let!(:payment_commitment) { create(:payment_commitment, sponsor: sponsor) }
    before do
      get edit_payment_commitment_path(type: 'publisher', sponsor_id: sponsor.id, id: payment_commitment.id), xhr: true
    end

    it 'returns a successful response' do
      expect(response).to have_http_status(200)
    end

    it 'responds with javascript' do
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('javascript')
    end
  end

  describe 'PUT #update' do
    let(:payment_commitment) { create(:payment_commitment, sponsor: sponsor) }

    before do
      put payment_commitment_path(type: 'publisher', sponsor_id: sponsor.id, id: payment_commitment.id), xhr: true, params: params
    end

    context 'with valid parameters' do
      let(:params) do
        {
          id: payment_commitment.id,
          payment_commitment: {
            start_date: '2026-01-01',
            period_discount: 50.0,
            consortium_discount: 10.0,
            dpc_commitment: 150.0,
            dpc_carryover: 75.0,
            dpc_commitment_price: 10.0,
            covers_ldf: 'false',
            ldf_size_limit: 150,
            ldf_commitment: 250.0,
            ldf_carryover: 125.0,
            asf: 10_000,
            asf_prepaid: 90.0,
            note: 'Updated commitment'
          }
        }
      end

      it 'updates the payment commitment' do
        payment_commitment.reload

        expect(payment_commitment.period_discount).to eq(50)
        expect(payment_commitment.asf_due).to eq(4500)
        expect(response).to have_http_status(200)
      end
    end

    context 'with invalid parameters' do
      let(:params) do
        {
          type: 'publisher',
          sponsor_id: sponsor.id,
          id: payment_commitment.id,
          payment_commitment: {
            start_date: '',
            period_discount: 'invalid',
            dpc_commitment: 150.0,
            note: ''
          }
        }
      end

      it 'does not update the payment commitment' do
        original_commitment = payment_commitment.dup
        payment_commitment.reload

        expect(payment_commitment.period_discount).to eq(original_commitment.period_discount)
        expect(response).to be_successful
        expect(flash.now[:alert]).to be_present
      end
    end
  end

  describe 'authorization' do
    let!(:user) { create(:user, role: 'admin', tenant_id: 'dryad') }

    context 'GET #index' do
      before do
        get payment_commitments_path(type: 'publisher', sponsor_id: sponsor.id)
      end

      it_should_behave_like 'user with no access'
    end

    context 'GET #new' do
      before do
        get new_payment_commitment_path(type: 'publisher', sponsor_id: sponsor.id, format: :js), xhr: true
      end

      it_should_behave_like 'user with no access'
    end

    context 'GET #edit' do
      let!(:payment_commitment) { create(:payment_commitment, sponsor: sponsor) }
      before do
        get edit_payment_commitment_path(type: 'publisher', sponsor_id: sponsor.id, id: payment_commitment.id), xhr: true
      end

      it_should_behave_like 'user with no access'
    end

    context 'POST #create' do
      before do
        post payment_commitments_path(type: 'publisher', sponsor_id: sponsor.id), xhr: true, params: { asf: 123 }
      end

      it_should_behave_like 'user with no access'
    end

    context 'PUT #update' do
      let!(:payment_commitment) { create(:payment_commitment, sponsor: sponsor) }
      before do
        put payment_commitment_path(type: 'publisher', sponsor_id: sponsor.id, id: payment_commitment.id), xhr: true, params: { asf: 123 }
      end

      it_should_behave_like 'user with no access'
    end
  end
end
