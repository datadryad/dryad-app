require 'spec_helper'

module Stash
  module Merritt
    describe SubmissionPackage do
      describe :payload do
        it 'is abstract' do
          resource = double(StashEngine::Resource)
          allow(resource).to receive(:identifier_str).and_return('doi:10.123/456')
          packaging = Stash::Deposit::Packaging::SIMPLE_ZIP
          package = SubmissionPackage.new(resource: resource, packaging: packaging)
          expect { package.payload }.to raise_error(NoMethodError)
        end
      end
    end
  end
end
