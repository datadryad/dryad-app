require 'models'
require 'stash/harvester/oai'

FactoryGirl.define do
  # TODO: Find a way to do modules w/o making model class name explicit
  factory :harvest_job, class: Stash::Harvester::Models::HarvestJob do

    status :completed

    factory :indexed_harvest_job do

      transient do
        record_count 5
        deleted false
        index_job_status :completed
        index_record_status :completed
      end

      from_time Time.utc(2012, 1, 1)
      until_time { from_time + record_count.minutes if from_time }
      # query_url { "http://oai.datacite.org/oai?verb=ListRecords&metadataPrefix=oai_dc&from_time=#{from_time.utc.xmlschema}&until_time=#{until_time.utc.xmlschema}" }
      query_url { "http://oai.datacite.org/oai?verb=ListRecords&metadataPrefix=oai_dc#{'&from_time=' + from_time.utc.xmlschema if from_time}#{'&until_time=' + until_time.utc.xmlschema if until_time}" }
      start_time Time.utc(2015, 1, 1)
      end_time { start_time + record_count.minutes }

      after(:create) do |harvest_job, evaluator|
        from_timestamp = harvest_job.from_time || Time.utc(2012, 1, 1)

        record_count = evaluator.record_count
        deleted = evaluator.deleted
        index_record_status = evaluator.index_record_status

        harvest_end_time = harvest_job.end_time
        index_start_time = harvest_end_time + 5.minutes
        index_end_time = index_start_time + record_count.minutes

        harvested_records = Array.new(record_count) do |index|
          create(
            :harvested_record,
            harvest_job: harvest_job,
            identifier: "record#{index}",
            timestamp: from_timestamp + index.minutes,
            deleted: deleted,
            content_path: ("/tmp/record#{index}.xml" unless deleted)
          )
        end

        index_job = create(
          :index_job,
          solr_url: 'http://solr.example.org/',
          harvest_job: harvest_job,
          start_time: index_start_time,
          end_time: index_end_time,
          status: evaluator.index_job_status
        )
        harvested_records.each_with_index do |harvested_record, index|
          create(
            :indexed_record,
            index_job: index_job,
            harvested_record: harvested_record,
            submitted_time: index_start_time + index.minutes,
            status: index_record_status
          )
        end
      end
    end

  end
end
