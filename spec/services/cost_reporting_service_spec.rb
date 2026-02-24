RSpec.shared_examples('does not send ldf notification') do
  it 'does not send emails' do
    expect(StashEngine::ResourceMailer).not_to receive(:ld_publication)
    expect(StashEngine::ResourceMailer).not_to receive(:ld_submission)
    expect { subject }.not_to(change { StashEngine::CurationActivity.count })
  end
end

RSpec.shared_examples('sends ldf notification') do
  it 'send emails and created activity entry' do
    expect(mock_mailer).to receive(:deliver_now)
    expect { subject }.to change { StashEngine::CurationActivity.count }.by(1)
  end
end

describe CostReportingService do
  let(:tenant) { create(:tenant, campus_contacts: ['some@email.com'].to_json) }
  let(:identifier) { create(:identifier) }
  let!(:journal) { create(:journal) }
  let!(:payment_conf) { create(:payment_configuration, partner: journal, payment_plan: '2025', covers_ldf: true) }
  let(:prev_resource) do
    create(:resource,
           identifier: identifier,
           journal_issns: [journal.issns.first],
           total_file_size: prev_files_size,
           created_at: 2.minutes.ago,
           tenant: tenant)
  end
  let(:resource) do
    create(:resource,
           identifier: identifier,
           journal_issns: [journal.issns.first],
           total_file_size: resource_files_size,
           tenant: tenant)
  end

  let(:prev_files_size) { 11_000_000_000 }
  let(:resource_files_size) { 11_000_000_000 }
  let(:mock_mailer) { double(deliver_now: true) }

  subject { CostReportingService.new(resource).notify_partner_of_large_data_submission }

  before(:each) do
    allow(identifier).to receive(:payer).and_return(double(id: 1))
  end

  context :notify_partner_of_large_data_submission do
    context 'when user is the payer' do
      let!(:resource) { create(:resource, identifier: identifier, total_file_size: resource_files_size) }

      include_examples 'does not send ldf notification'
    end

    context 'when status changes to wrong value' do
      before do
        create(:curation_activity, :curation, resource: resource)
      end

      include_examples 'does not send ldf notification'
    end

    context 'when status changes to queued' do
      before(:each) do
        expect(StashEngine::ResourceMailer).not_to receive(:ld_publication)
        allow(StashEngine::ResourceMailer).to receive(:ld_submission).and_return(mock_mailer)
      end

      context 'on first submission' do
        before do
          create(:curation_activity, :queued, resource: resource)
        end

        include_examples 'sends ldf notification'

        context 'when non 2025 plan institution is the payer' do
          let!(:payment_conf) { create(:payment_configuration, partner: journal, payment_plan: 'TIERED') }
          let!(:resource) { create(:resource, identifier: identifier, total_file_size: resource_files_size) }

          include_examples 'does not send ldf notification'
        end

        context 'where there is no tenant' do
          let(:tenant) { nil }

          include_examples 'does not send ldf notification'
        end

        context 'where the tenant campus_contacts is not set' do
          let(:tenant) { create(:tenant, campus_contacts: [].to_json) }

          include_examples 'does not send ldf notification'
        end

        context 'another curation activity with same status exists' do
          before do
            create(:curation_activity, :queued, resource: resource, note: 'some note')
          end

          include_examples 'does not send ldf notification'
        end

        context 'and the email was already sent once' do
          before do
            create(:curation_activity, :queued, resource: resource,
                                                note: 'Sending large data notification for status: queued')
          end

          include_examples 'does not send ldf notification'

          context 'on an new CA' do
            before do
              create(:curation_activity, :queued, resource: resource)
            end

            include_examples 'does not send ldf notification'
          end
        end
      end

      context 'on second submission' do
        context 'when initial submission has same status' do
          before do
            create(:curation_activity, :queued, resource: prev_resource)
            create(:curation_activity, :queued, resource: resource)
          end

          context 'and files_size tier does not change' do
            context 'and no email was sent before' do
              include_examples 'does not send ldf notification'
            end

            context 'and the email was already sent once' do
              before do
                create(:curation_activity, :queued, resource: resource,
                                                    note: 'Sending large data notification for status: queued')
              end

              include_examples 'does not send ldf notification'

              context 'on an new CA' do
                before do
                  create(:curation_activity, :queued, resource: resource)
                end

                include_examples 'does not send ldf notification'
              end
            end
          end

          context 'when files_size tier changes' do
            let(:resource_files_size) { 200_000_000_000 }

            include_examples 'sends ldf notification'
          end
        end

        context 'when initial submission has wrong status' do
          before do
            create(:curation_activity, :in_progress, resource: prev_resource)
            create(:curation_activity, :queued, resource: resource)
          end

          include_examples 'sends ldf notification'
        end
      end
    end

    context 'when status changes to embargoed' do
      context 'on first publish' do
        before do
          create(:curation_activity, :embargoed, resource: resource)
        end

        include_examples 'does not send ldf notification'

      end
    end

    context 'when status changes to published' do
      before(:each) do
        expect(StashEngine::ResourceMailer).not_to receive(:ld_submission)
        allow(StashEngine::ResourceMailer).to receive(:ld_publication).and_return(mock_mailer)
      end

      context 'on first publish' do
        before do
          create(:curation_activity, :published, resource: resource)
        end

        include_examples 'sends ldf notification'

        context 'when non 2025 plan institution is the payer' do
          let!(:payment_conf) { create(:payment_configuration, partner: journal, payment_plan: 'TIERED') }
          let!(:resource) { create(:resource, identifier: identifier, total_file_size: resource_files_size) }

          include_examples 'does not send ldf notification'
        end

        context 'another curation activity with same status exists' do
          before do
            create(:curation_activity, :published, resource: resource, note: 'some note')
          end

          include_examples 'does not send ldf notification'
        end

        context 'and the email was already sent once' do
          before do
            create(:curation_activity, :published, resource: resource,
                                                   note: 'Sending large data notification for status: published')
          end

          include_examples 'does not send ldf notification'

          context 'on an new CA' do
            before do
              create(:curation_activity, :published, resource: resource)
            end

            include_examples 'does not send ldf notification'
          end
        end
      end

      context 'and the email for queued status was sent' do
        before do
          create(:curation_activity, :queued, resource: resource,
                                              note: 'Sending large data notification for status: queued')
          create(:curation_activity, :published, resource: resource)
        end

        include_examples 'sends ldf notification'
      end

      context 'on second submission' do
        context 'when initial submission has proper status' do
          before do
            create(:curation_activity, :published, resource: prev_resource)
            create(:curation_activity, :published, resource: resource)
          end

          context 'and files_size tier does not change' do
            context 'and no email was sent before' do
              include_examples 'does not send ldf notification'
            end

            context 'and the email was already sent once' do
              before do
                create(:curation_activity, :published, resource: resource,
                                                       note: 'Sending large data notification for status: published')
              end

              include_examples 'does not send ldf notification'

              context 'on an new CA' do
                before do
                  create(:curation_activity, :published, resource: resource)
                end

                include_examples 'does not send ldf notification'
              end
            end
          end

          context 'when files_size tier changes' do
            let(:resource_files_size) { 200_000_000_000 }

            include_examples 'sends ldf notification'
          end
        end

        context 'when initial submission has wrong status' do
          before do
            create(:curation_activity, :queued, resource: prev_resource)
            create(:curation_activity, :published, resource: resource)
          end

          include_examples 'sends ldf notification'
        end
      end
    end
  end
end
