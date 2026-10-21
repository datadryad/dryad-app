module Mocks
  module Domains
    def mock_domains!
      domains = 3.times.map { OpenStruct.new(subject: Faker::Job.unique.field) }
      allow(StashDatacite::Subject).to receive(:fos).and_return(domains)
    end
  end
end
