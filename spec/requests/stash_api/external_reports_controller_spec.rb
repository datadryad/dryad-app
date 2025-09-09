require 'rails_helper'
require 'uri'
require_relative 'helpers'
require 'fixtures/stash_api/metadata'
require 'fixtures/stash_api/curation_metadata'
require 'cgi'
# see https://relishapp.com/rspec/rspec-rails/v/3-8/docs/request-specs/request-spec
module StashApi
  RSpec.describe ExternalReportsController, type: :request do
    subject { ExternalReportsController.new }

    describe '#report_object' do
      it 'raises NotImplementedError' do
        expect { subject.send(:report_object) }.to raise_error(NotImplementedError, 'Subclasses must implement report_object')
      end
    end

    describe '#statuses' do
      it 'raises NotImplementedError' do
        expect { subject.send(:statuses) }.to raise_error(NotImplementedError, 'Subclasses must implement statuses')
      end
    end
  end
end
