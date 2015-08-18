require 'db_spec_helper'

describe 'FactoryGirl factories' do
  # See https://robots.thoughtbot.com/testing-your-factories-first
  FactoryGirl.factories.map(&:name).each do |factory_name|
    describe "The #{factory_name} factory" do
      it 'is valid' do
        model_instance = build(factory_name)
        expect(model_instance).to be_valid
        expect(model_instance).to be_new_record
      end

      it 'persists on create' do
        model_instance = create(factory_name)
        expect(model_instance).to be_persisted
      end
    end
  end

  describe ":indexed_harvest_job" do
    it 'has a working factory' do
      count = 3

      create(:indexed_harvest_job, record_count: count, from_time: Time.utc(2013, 1, 1), start_time: Time.utc(2015, 1, 1))

      expect(Stash::Harvester::Models::HarvestJob.count).to eq(1)
      harvest_job = Stash::Harvester::Models::HarvestJob.first
      expect(harvest_job.from_time).to eq(Time.utc(2013, 1, 1))
      expect(harvest_job.until_time).to eq(Time.utc(2013, 1, 1, 0, count))
      expect(harvest_job.query_url).to eq("http://oai.datacite.org/oai?verb=ListRecords&metadataPrefix=oai_dc&from_time=#{ harvest_job.from_time.xmlschema }&until_time=#{ harvest_job.until_time.xmlschema }")
      expect(harvest_job.start_time).to eq(Time.utc(2015, 1, 1))
      expect(harvest_job.end_time).to eq(Time.utc(2015, 1, 1, 0, count))
      expect(harvest_job.completed?).to be true

      expect(harvest_job.harvested_records.count).to eq(count)

      harvest_job.harvested_records.each_with_index do |r, i|
        expect(r.identifier).to eq("record#{i}")
        expect(r.timestamp).to eq(harvest_job.from_time + i.minutes)
        expect(r.deleted?).to be false
        expect(r.content_path).to eq("/tmp/#{r.identifier}.xml")
        expect(r.indexed_records.count).to eq(1)
      end

      expect(harvest_job.index_jobs.count).to eq(1)
      index_job = harvest_job.index_jobs.first
      expect(index_job.solr_url).to eq('http://solr.example.org/')
      expect(index_job.harvest_job).to eq(harvest_job)
      expect(index_job.start_time).to eq(harvest_job.end_time + 5.minutes)
      expect(index_job.end_time).to eq(index_job.start_time + count.minutes)
      expect(index_job.completed?).to be true

      expect(index_job.indexed_records.count).to eq(count)
      index_job.indexed_records.each_with_index do |r, i|
        expect(r.index_job).to eq(index_job)
        expect(r.harvested_record).to eq(harvest_job.harvested_records[i])
        expect(r.submitted_time).to eq(index_job.start_time + i.minutes)
        expect(r.completed?).to be true
      end
    end
  end
end

