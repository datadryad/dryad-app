# spec/services/submission/files_service_spec.rb
require 'rails_helper'

RSpec.describe Submission::FilesService do
  let(:identifier) { create(:identifier) }
  let(:resource) { create(:resource, identifier: identifier) }
  let(:file) { create(:data_file, resource: resource, file_state: file_state) }
  let(:file_state) { 'created' }

  let(:service) { described_class.new(file) }

  describe '#initialize' do
    subject { service }

    it 'sets proper attributes' do
      expect(subject.resource).to eq(resource)
      expect(subject.file).to eq(file)
    end
  end

  describe '#copy_file' do
    subject { service.copy_file }

    context 'for "created" file' do
      context 'with uploaded file' do
        it 'calls #copy_to_permanent_store' do
          expect(service).to receive(:copy_to_permanent_store)
          subject
        end
      end

      context 'with remote file' do
        let(:file) { create(:data_file, resource: resource, file_state: file_state, url: 'some_url') }

        context 'with no file uploaded on stage AWS bucket' do
          before do
            allow_any_instance_of(Stash::Aws::S3).to receive(:exists?).and_return(false)
          end

          it 'calls #copy_external_to_permanent_store' do
            expect(service).to receive(:copy_external_to_permanent_store).and_return(true)
            subject
          end
        end
      end

      context 'with an file uploaded on stage AWS bucket' do
        before do
          allow_any_instance_of(Stash::Aws::S3).to receive(:exists?).and_return(true)
        end

        it 'calls #copy_to_permanent_store' do
          expect(service).to receive(:copy_to_permanent_store).and_return(true)
          subject
        end
      end
    end

    context 'for "copied" file' do
      let(:file_state) { 'copied' }

      it 'calls #copy_to_permanent_store' do
        expect(service).not_to receive(:copy_to_permanent_store)
        expect(service).not_to receive(:copy_external_to_permanent_store)
        subject
      end
    end

    context 'for "deleted" file' do
      let(:file_state) { 'deleted' }

      it 'calls #copy_to_permanent_store' do
        expect(service).not_to receive(:copy_to_permanent_store)
        expect(service).not_to receive(:copy_external_to_permanent_store)
        subject
      end
    end
  end
end
