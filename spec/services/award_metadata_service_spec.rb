describe AwardMetadataService do
  let(:nih_contrib) { create(:contributor, award_number: 'R01HD113192', name_identifier_id: NIH_ROR, contributor_name: 'Original name') }
  let(:nih_contrib_no_award) { create(:contributor, award_number: '', name_identifier_id: NIH_ROR) }
  let(:nsf_contrib) { create(:contributor, award_number: '1457726', name_identifier_id: NSF_ROR) }
  let(:nsf_contrib_no_award) { create(:contributor, award_number: '', name_identifier_id: NSF_ROR) }
  let(:other_contrib) { create(:contributor, award_number: '12345', name_identifier_id: 'https://ror.org/028rq5v79') }

  before do
    allow(Rails.cache).to receive(:fetch).and_wrap_original do |_m, *_args, &block|
      block.call # always run the block, skip caching
    end
  end

  describe '#initialize' do
    context 'with NIH contributor' do
      it 'sets the proper attributes' do
        service = described_class.new(nih_contrib)
        expect(service.contributor).to eq(nih_contrib)
        expect(service.api_integration_key).to eq('NIH')
      end
    end

    context 'with NSF contributor' do
      it 'sets the proper attributes' do
        service = described_class.new(nsf_contrib)
        expect(service.contributor).to eq(nsf_contrib)
        expect(service.api_integration_key).to eq('NSF')
      end
    end

    context 'with NIH contributor' do
      it 'sets the proper attributes' do
        service = described_class.new(other_contrib)
        expect(service.contributor).to eq(other_contrib)
        expect(service.api_integration_key).to eq(nil)
      end
    end
  end

  describe '#populate_from_api' do
    subject { described_class.new(contrib).populate_from_api }

    context 'for NIH API' do
      let(:contrib) { nih_contrib }

      context 'when there is no award number' do
        let(:contrib) { nih_contrib_no_award }

        it 'does not do any update' do
          expect(subject).to be_nil
          expect(contrib.reload.award_title).to be_nil
        end
      end

      context 'when there is a valid award number' do
        let(:nih_api_response) do
          {
            'project_num' => '5R01HD113192-03',
            'agency_ic_admin' => { 'code' => 'HD', 'abbreviation' => 'NI', 'name' => 'NIH Office of the Director' },
            'agency_ic_fundings' => [
              {
                'fy' => 2025, 'code' => 'HD', 'name' => 'NIH Office of the Director', 'abbreviation' => 'NI',
                'total_cost' => 299_925.0, 'direct_cost_ic' => 193_500.0, 'indirect_cost_ic' => 106_425.0
              }
            ],
            'core_project_num' => 'R01HD113192-RC2',
            'project_title' => 'Microbial-induced maternal factors that influence fetal immune development',
            'project_detail_url' => 'https://reporter.nih.gov/project-details/11169041',
            'date_added' => '2025-09-07T22:56:09'
          }
        end

        context 'when there is no contributor grouping data' do
          it 'updates record info without ROR' do
            VCR.use_cassette('nih_api/award_one_result_found') do
              expect(subject).not_to be_nil
              contrib.reload

              expect(contrib.award_title).to eq('Microbial-induced maternal factors that influence fetal immune development')
              expect(contrib.award_uri).to eq('https://reporter.nih.gov/project-details/11169041')
              expect(contrib.name_identifier_id).to eq(NIH_ROR)
              expect(contrib.contributor_name).to eq('Original name')
            end
          end

          it 'sends email related to missing ROR information' do
            VCR.use_cassette('nih_api/award_one_result_found') do
              expect(StashEngine::NotificationsMailer).to receive(:nih_child_missing).with(contrib.id, nih_api_response)
                .once.and_return(double(deliver_now: true))

              expect(subject).not_to be_nil
            end
          end
        end

        context 'with contributor grouping data' do
          let!(:nih_grouping) do
            create(:contributor_grouping,
                   name_identifier_id: NIH_ROR,
                   identifier_type: 'ror',
                   json_contains: [
                     {
                       'identifier_type' => 'ror', 'contributor_name' => 'NIH Office of the Director',
                       'contributor_type' => 'funder', 'name_identifier_id' => 'https://ror.org/00fj8a872'
                     }
                   ])
          end

          it 'updates record ror data' do
            VCR.use_cassette('nih_api/award_one_result_found') do
              expect(subject).not_to be_nil
              contrib.reload
              expect(contrib.award_title).to eq('Microbial-induced maternal factors that influence fetal immune development')
              expect(contrib.award_uri).to eq('https://reporter.nih.gov/project-details/11169041')
              expect(contrib.name_identifier_id).to eq('https://ror.org/00fj8a872')
              expect(contrib.contributor_name).to eq('NIH Office of the Director')
            end
          end

          context 'with contributor auto_update set to false' do
            before { contrib.update(auto_update: false) }

            let(:nih_contrib) { create(:contributor, award_number: 'R01HD113192', name_identifier_id: NIH_ROR, contributor_name: 'Original name') }

            it 'does not update record data' do
              VCR.use_cassette('nih_api/award_one_result_found') do
                expect { subject }.not_to(change { contrib.reload })
              end
            end
          end
        end

        context 'with contributor name is different but is in mapped names' do
          let!(:nih_grouping) do
            create(:contributor_grouping,
                   name_identifier_id: NIH_ROR,
                   identifier_type: 'ror',
                   json_contains: [
                     {
                       'identifier_type' => 'ror', 'contributor_name' => 'Office of the Director',
                       'contributor_type' => 'funder', 'name_identifier_id' => 'https://ror.org/00fj8a872'
                     }
                   ])
          end

          it 'updates record ror data using the name from the database' do
            VCR.use_cassette('nih_api/award_one_result_found') do
              expect(subject).not_to be_nil
              contrib.reload
              expect(contrib.award_title).to eq('Microbial-induced maternal factors that influence fetal immune development')
              expect(contrib.award_uri).to eq('https://reporter.nih.gov/project-details/11169041')
              expect(contrib.name_identifier_id).to eq('https://ror.org/00fj8a872')
              expect(contrib.contributor_name).to eq('Office of the Director')
            end
          end
        end

        context 'with contributor name is different but is in mapped names but not in the database' do
          it 'updates record without updating ROR' do
            VCR.use_cassette('nih_api/award_one_result_found') do
              expect(subject).not_to be_nil
              contrib.reload

              expect(contrib.award_title).to eq('Microbial-induced maternal factors that influence fetal immune development')
              expect(contrib.award_uri).to eq('https://reporter.nih.gov/project-details/11169041')
              expect(contrib.name_identifier_id).to eq(NIH_ROR)
              expect(contrib.contributor_name).to eq('Original name')
            end
          end

          it 'sends email related to missing ROR information' do
            VCR.use_cassette('nih_api/award_one_result_found') do
              expect(StashEngine::NotificationsMailer).to receive(:nih_child_missing).with(contrib.id, nih_api_response)
                .once.and_return(double(deliver_now: true))

              expect(subject).not_to be_nil
            end
          end
        end
      end

      context 'when there is an invalid award number' do
        it 'does not do any update' do
          VCR.use_cassette('nih_api/award_no_result_found') do
            expect(subject).to be_nil
            expect(contrib.reload.award_title).to be_nil
          end
        end
      end

      context 'when there are multiple records based on award number' do
        it 'updates based on newest record' do
          VCR.use_cassette('nih_api/award_multiple_result_found') do
            expect(subject).not_to be_nil
            contrib.reload

            expect(contrib.award_title).to eq('Microbial-induced maternal factors that influence fetal immune development 1')
            expect(contrib.award_uri).to eq('https://reporter.nih.gov/project-details/11169041')
          end
        end
      end
    end

    context 'for NSF API' do
      let(:contrib) { nsf_contrib }

      context 'when there is no award number' do
        let(:contrib) { nsf_contrib_no_award }

        it 'does not do any update' do
          expect(subject).to be_nil
          expect(contrib.reload.award_title).to be_nil
        end
      end

      context 'when there is a valid award number' do
        context 'with no grouping' do
          it 'updates record info' do
            VCR.use_cassette('nsf_api/award_one_result_found') do
              expect(subject).not_to be_nil
              contrib.reload

              expect(contrib.award_title).to eq('Collaborative Research: A Comparative Phylogeographic Approach to Predicting Cryptic Diversity')
              expect(contrib.award_uri).to be_nil
            end
          end
        end

        context 'with level 1 grouping' do
          let!(:l1_grouping) do
            create(:contributor_grouping,
                   name_identifier_id: NSF_ROR,
                   identifier_type: 'ror',
                   json_contains: [
                     {
                       'identifier_type' => 'ror', 'contributor_name' => 'Division Of Environmental Biology',
                       'contributor_type' => 'funder', 'name_identifier_id' => 'https://ror.org/12345678'
                     }
                   ])
          end

          it 'updates record info' do
            VCR.use_cassette('nsf_api/award_one_result_found') do
              expect(subject).not_to be_nil
              contrib.reload

              expect(contrib.award_title).to eq('Collaborative Research: A Comparative Phylogeographic Approach to Predicting Cryptic Diversity')
              expect(contrib.award_uri).to be_nil
              expect(contrib.contributor_name).to eq('Division Of Environmental Biology')
              expect(contrib.name_identifier_id).to eq('https://ror.org/12345678')
            end
          end
        end

        context 'with level 1 grouping' do
          let!(:l1_grouping) do
            create(:contributor_grouping,
                   name_identifier_id: NSF_ROR,
                   identifier_type: 'ror',
                   json_contains: [
                     {
                       'identifier_type' => 'ror', 'contributor_name' => 'Level 1 Grouping',
                       'contributor_type' => 'funder', 'name_identifier_id' => 'https://ror.org/12345678'
                     }
                   ])
          end

          let!(:l2_contributor) { create(:contributor, name_identifier_id: 'https://ror.org/12345678', contributor_name: 'Division Of Environmental Biology') }
          let!(:l2_grouping) do
            create(:contributor_grouping,
                   name_identifier_id: 'https://ror.org/12345678',
                   identifier_type: 'ror',
                   json_contains: [
                     {
                       'identifier_type' => 'ror', 'contributor_name' => 'Division Of Environmental Biology',
                       'contributor_type' => 'funder', 'name_identifier_id' => 'https://ror.org/987654321'
                     }
                   ])
          end

          it 'updates record info' do
            VCR.use_cassette('nsf_api/award_one_result_found') do
              expect(subject).not_to be_nil
              contrib.reload

              expect(contrib.award_title).to eq('Collaborative Research: A Comparative Phylogeographic Approach to Predicting Cryptic Diversity')
              expect(contrib.award_uri).to be_nil
              expect(contrib.contributor_name).to eq('Division Of Environmental Biology')
              expect(contrib.name_identifier_id).to eq('https://ror.org/987654321')
            end
          end
        end
      end

      context 'when there is an in valid award number' do
        it 'does not do any update' do
          VCR.use_cassette('nsf_api/award_no_result_found') do
            expect(subject).to be_nil
            expect(contrib.reload.award_title).to be_nil
          end
        end
      end

      context 'when there are multiple records based on award number' do
        it 'updates based on newest record' do
          VCR.use_cassette('nsf_api/award_multiple_result_found') do
            expect(subject).not_to be_nil
            contrib.reload

            expect(contrib.award_title).to eq('Collaborative Research: A Comparative Phylogeographic Approach to Predicting Cryptic Diversity 1')
            expect(contrib.contributor_name).not_to eq('Original name')
          end
        end
      end
    end
  end
end
