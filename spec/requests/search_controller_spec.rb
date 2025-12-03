RSpec.describe 'SearchController', type: :request do
  let(:service_instance) { double(StashApi::SolrSearchService) }
  let(:extra_field) { '' }
  let(:options) do
    {
      facet: true,
      fields: "dc_identifier_s dc_title_s dc_creator_sm dc_description_s dc_subject_sm dct_issued_dt#{extra_field}",
      page: 1,
      per_page: 10
    }
  end

  describe '#new_search_url' do
    before do
      allow(StashApi::SolrSearchService).to receive(:new)
        .with(query: query, filters: ActionController::Parameters.new(filters)).and_return(service_instance)
      allow(service_instance).to receive(:search).with(**options).and_return(options)
      allow(service_instance).to receive(:error)
      get new_search_url, params: { q: query }.merge(filters)
    end

    describe '#result_fields' do
      let(:query) { '' }
      let(:filters) { {} }

      context 'without parameters' do
        it 'calls new with the correct type' do
          expect(StashApi::SolrSearchService).to have_received(:new).with(query: query, filters: ActionController::Parameters.new(filters))
        end

        it 'calls search with the correct params' do
          expect(service_instance).to have_received(:search).with(**options)
        end
      end

      context 'with funder search' do
        let(:filters) { { funder: 'test' } }
        let(:extra_field) { ' funding_sm' }

        it 'calls search with the correct params' do
          expect(service_instance).to have_received(:search).with(**options)
        end
      end

      context 'with file extension search' do
        let(:filters) { { fileExt: 'test' } }
        let(:extra_field) { ' dryad_dataset_file_ext_sm' }

        it 'calls search with the correct params' do
          expect(service_instance).to have_received(:search).with(**options)
        end
      end

      context 'with affiliation search' do
        let(:filters) { { affiliation: 'test' } }
        let(:extra_field) { ' dryad_author_affiliation_name_sm' }

        it 'calls search with the correct params' do
          expect(service_instance).to have_received(:search).with(**options)
        end
      end

      context 'with journal search' do
        let(:filters) { { journalISSN: 'test' } }
        let(:extra_field) { ' dryad_related_publication_name_s' }

        it 'calls search with the correct params' do
          expect(service_instance).to have_received(:search).with(**options)
        end
      end
    end
  end
end
