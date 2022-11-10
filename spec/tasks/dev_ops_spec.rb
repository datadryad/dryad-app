require 'rails_helper'
require 'byebug'
require 'cgi'

describe 'dev_ops:retry_zenodo_errors', type: :task do
  it 'preloads the Rails environment' do
    expect(task.prerequisites).to include 'environment'
  end

  it 'logs to stdout' do
    expect { task.execute }.to output(/Re-enqueuing errored ZenodoCopies/).to_stdout
  end

  describe 'selects the errored ones' do
    before(:each) do
      ident = create(:identifier)
      ident2 = create(:identifier)
      @zc1 = create(:zenodo_copy, state: 'error', retries: 5, identifier_id: ident.id)
      @zc2 = create(:zenodo_copy, state: 'error', retries: 0, identifier_id: ident2.id)
      allow(StashEngine::ZenodoCopyJob).to receive(:perform_later).and_return(nil)
    end

    it 'only processes ones with less than 4 retries (zenodo_copy)' do
      expect { task.execute }.to output(/Adding resource_id: #{@zc2.resource_id}/).to_stdout
      @zc1.reload
      @zc2.reload
      expect(@zc2.state).to eq('enqueued')
      expect(@zc1.state).to eq('error')
    end

    it 'processes ones with less than 4 retries (zenodo software)' do
      @zc1.update(copy_type: 'software')
      @zc2.update(copy_type: 'software')
      expect { task.execute }.to output(/Adding resource_id: #{@zc2.resource_id}/).to_stdout
      @zc1.reload
      @zc2.reload
      expect(@zc2.state).to eq('enqueued')
      expect(@zc1.state).to eq('error')
    end
  end
end

describe 'dev_ops:long_jobs', type: :task do

  it 'detects no jobs if none in interesting states' do
    create(:repo_queue_state, state: 'completed')
    ident = create(:identifier)
    create(:zenodo_copy, state: 'finished', identifier_id: ident.id)
    expect { task.execute }.to output(/0\sitems\sin\sMerritt.+
      0\sitems\sare\sbeing\ssent\sto\sMerritt.+
      0\sitems\sin\sZenodo.+
      0\sitems\sare\sstill\sbeing\sreplicated\sto\sZenodo/xm).to_stdout
  end

  it 'detects Merritt queued and executing' do
    create(:repo_queue_state, state: 'enqueued')
    create(:repo_queue_state, state: 'processing')
    expect { task.execute }.to output(/1\sitems\sin\sMerritt.+
      1\sitems\sare\sbeing\ssent\sto\sMerritt.+/xm).to_stdout
  end

  it 'detects zenodo queued and executing' do
    ident = create(:identifier)
    ident2 = create(:identifier)
    create(:zenodo_copy, state: 'enqueued', identifier_id: ident.id)
    create(:zenodo_copy, state: 'replicating', identifier_id: ident2.id)
    expect { task.execute }.to output(/1\sitems\sin\sZenodo.+
      1\sitems\sare\sstill\sbeing\sreplicated\sto\sZenodo/xm).to_stdout
  end

end

describe 'dev_ops:download_uri', type: :task do
  it 'runs the rake task' do
    test_path = File.join(Rails.root, 'spec', 'fixtures', 'merritt_ark_changing_test.txt')
    argv = ['', test_path]
    stub_const('ARGV', argv)
    expect { task.execute }.to output(/Done/).to_stdout
  end

  describe 'testing updates from file' do
    before(:each) do
      @test_path = File.join(Rails.root, 'spec', 'fixtures', 'merritt_ark_changing_test.txt')
    end

    it 'loads the file and calls updates' do
      # testing one specific value from the file
      expect(Tasks::DevOps::DownloadUri).to receive(:update) \
        .with(doi: 'doi:10.5072/FK20R9S858', old_ark: 'ark:/99999/fk4np2b23p', new_ark: 'ark:/99999/fk4cv5xm2w').once
      # testing that it is called for the other 11
      expect(Tasks::DevOps::DownloadUri).to receive(:update).at_least(11).times
      Tasks::DevOps::DownloadUri.update_from_file(file_path: @test_path)
    end

    it 'updates the database download_uri and update_uri' do
      resource = create(:resource)
      old_time = Time.parse('2020-10-11').utc
      old_update_uri = resource.update_uri
      resource.update(updated_at: old_time)
      # the throwaway resource is just to obtain another download_uri and ark to test for the new_ark and transformation
      throwaway_resource = create(:resource)
      expect(resource.download_uri).not_to eq(throwaway_resource.download_uri)

      old_ark = CGI.unescape(resource.download_uri.match(%r{[^/]+$}).to_s)
      new_ark = CGI.unescape(throwaway_resource.download_uri.match(%r{[^/]+$}).to_s)

      Tasks::DevOps::DownloadUri.update(doi: resource.identifier.to_s, old_ark: old_ark, new_ark: new_ark)

      resource.identifier.resources.each do |res|
        expect(res.download_uri).to eq(throwaway_resource.download_uri)
        expect(res.update_uri).not_to eq(old_update_uri)
        expect(res.update_uri[-28..]).to eq(old_update_uri[-28..]) # last (doi) of string should be the same
        expect(res.update_uri).to include('/cdl_dryad/') # because we're always moving into that collection
        expect(res.updated_at).to eq(old_time)
      end
    end
  end
end
