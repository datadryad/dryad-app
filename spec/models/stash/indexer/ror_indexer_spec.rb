module Stash
  module Indexer
    describe RorIndexer do
      let!(:ror) do
        create(
          :ror_org,
          ror_id: 'some_unique_id',
          name: 'ROR name',
          acronyms: %w[test common],
          aliases: %w[atest alias],
          country: 'US'
        )
      end
      let(:mock_response) { { 'responseHeader' => { 'status' => 0 } } }
      let(:solr_mock) { instance_double(RSolr::Client, add: true, commit: true) }

      before do
        allow(RSolr).to receive(:connect).and_return(solr_mock)
      end

      describe '#index_mappings' do
        it 'maps needed values' do
          expect(ror.index_mappings).to eq(
            {
              id: ror.id.to_s,
              name: 'ROR name',
              ror_id: 'some_unique_id',
              country: 'US',
              acronyms: %w[test common],
              aliases: %w[atest alias],
              home_page: nil,
              isni_ids: nil
            }
          )
        end
      end

      describe '#search' do
        it 'by query string' do
          filters = { q: 'test' }
          expect(solr_mock).to receive(:get).with('select', params: filters, rows: 100).and_return(mock_response)

          StashEngine::RorOrg.search('test')
        end

        it 'by query field' do
          filters = { fq: 'name:some words* OR aliases:test' }
          expect(solr_mock).to receive(:get).with('select', params: filters, rows: 100).and_return(mock_response)

          StashEngine::RorOrg.search('', fq: ['name:some words*', 'aliases:test'])
        end

        it 'by query field with AND operation' do
          filters = { fq: 'name:some words* AND aliases:test' }
          expect(solr_mock).to receive(:get).with('select', params: filters, rows: 100).and_return(mock_response)

          StashEngine::RorOrg.search('', fq: ['name:some words*', 'aliases:test'], operation: 'AND')
        end

        it 'requests specific fields only' do
          filters = { fq: 'name:some words*', fl: 'id,name' }
          expect(solr_mock).to receive(:get).with('select', params: filters, rows: 100).and_return(mock_response)

          StashEngine::RorOrg.search('', fq: ['name:some words*'], fl: 'id,name')
        end

        it 'limits the results' do
          filters = { fq: 'name:some words*', fl: 'id,name' }
          expect(solr_mock).to receive(:get).with('select', params: filters, rows: 10).and_return(mock_response)

          StashEngine::RorOrg.search('', fq: ['name:some words*'], fl: 'id,name', limit: 10)
        end
      end

      describe '#create' do
        it 'triggers reindex' do
          expect_any_instance_of(StashEngine::RorOrg).to receive(:reindex).once.and_return(true)
          create(:ror_org)
        end
      end

      describe '#reindex' do
        it 'triggers add to solr' do
          expect(solr_mock).to receive(:add).and_return(mock_response)
          ror.reindex
        end
      end
    end
  end
end
