require 'spec_helper'

module Stash
  module Indexer
    describe IndexResult do
      describe 'initialize' do
        it 'sets the record' do
          record = instance_double(Stash::Harvester::HarvestedRecord)
          result = IndexResult.new(record: record)
          expect(result.record).to be(record)
        end

        it 'sets the status' do
          record = instance_double(Stash::Harvester::HarvestedRecord)
          result = IndexResult.new(record: record, status: IndexStatus::FAILED)
          expect(result.status).to be(IndexStatus::FAILED)
        end

        it 'defaults the status to COMPLETED' do
          record = instance_double(Stash::Harvester::HarvestedRecord)
          result = IndexResult.new(record: record)
          expect(result.status).to be(IndexStatus::COMPLETED)
        end

        it 'sets the error list' do
          record = instance_double(Stash::Harvester::HarvestedRecord)
          errors = [instance_double(StandardError), instance_double(RuntimeError)]
          result = IndexResult.new(record: record, errors: errors)
          expect(result.errors).to eq(errors)
        end

        it 'defaults to an empty error list' do
          record = instance_double(Stash::Harvester::HarvestedRecord)
          result = IndexResult.new(record: record)
          expect(result.errors).to eq([])
        end
      end

      describe 'success?' do
        it 'returns true if no errors and COMPLETED status' do
          record = instance_double(Stash::Harvester::HarvestedRecord)
          result = IndexResult.new(record: record)
          expect(result.success?).to eq(true)
        end

        it 'returns false if errors' do
          record = instance_double(Stash::Harvester::HarvestedRecord)
          errors = [instance_double(StandardError), instance_double(RuntimeError)]
          result = IndexResult.new(record: record, errors: errors)
          expect(result.success?).to eq(false)
        end

        it 'returns false if status failed' do
          record = instance_double(Stash::Harvester::HarvestedRecord)
          result = IndexResult.new(record: record, status: IndexStatus::FAILED)
          expect(result.success?).to eq(false)
        end
      end

      describe 'failure?' do
        it 'returns false if no errors and COMPLETED status' do
          record = instance_double(Stash::Harvester::HarvestedRecord)
          result = IndexResult.new(record: record)
          expect(result.failure?).to eq(false)
        end

        it 'returns true if errors' do
          record = instance_double(Stash::Harvester::HarvestedRecord)
          errors = [instance_double(StandardError), instance_double(RuntimeError)]
          result = IndexResult.new(record: record, errors: errors)
          expect(result.failure?).to eq(true)
        end

        it 'returns true if status failed' do
          record = instance_double(Stash::Harvester::HarvestedRecord)
          result = IndexResult.new(record: record, status: IndexStatus::FAILED)
          expect(result.failure?).to eq(true)
        end
      end

      describe 'errors?' do
        it 'returns false if no errors' do
          record = instance_double(Stash::Harvester::HarvestedRecord)
          result = IndexResult.new(record: record)
          expect(result.errors?).to eq(false)
        end

        it 'returns true if errors' do
          record = instance_double(Stash::Harvester::HarvestedRecord)
          errors = [instance_double(StandardError), instance_double(RuntimeError)]
          result = IndexResult.new(record: record, errors: errors)
          expect(result.errors?).to eq(true)
        end

        it 'is independent of status' do
          record = instance_double(Stash::Harvester::HarvestedRecord)
          result = IndexResult.new(record: record, status: IndexStatus::FAILED)
          expect(result.errors?).to eq(false)
        end
      end

      describe 'success' do
        it 'returns a successful result for the specified record' do
          record = instance_double(Stash::Harvester::HarvestedRecord)
          result = IndexResult.success(record)
          expect(result.record).to be(record)
          expect(result.status).to be(IndexStatus::COMPLETED)
          expect(result.errors).to eq([])
        end
      end

      describe 'failure' do
        it 'returns a failing result for the specified record, with the specified errors' do
          record = instance_double(Stash::Harvester::HarvestedRecord)
          errors = [instance_double(StandardError), instance_double(RuntimeError)]
          result = IndexResult.failure(record, errors)
          expect(result.record).to be(record)
          expect(result.status).to be(IndexStatus::FAILED)
          expect(result.errors).to eq(errors)
        end
      end
    end
  end
end
