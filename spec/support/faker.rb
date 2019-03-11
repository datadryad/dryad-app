require 'faker'

LOCALE = 'en'.freeze

RSpec.configure do |config|
  config.after(:each) do
    Faker::Name.unique.clear
    Faker::UniqueGenerator.clear
  end

end

module Faker

  class Pid < Base

    flexible :pid

    class << self

      def doi
        # Example: 12.1234/foo.b1a2r
        "#{Faker::Number.decimal(2, 4)}/#{Faker::Lorem.word}.#{Faker::Alphanumeric.alphanumeric 5}"
      end

      def orcid
        # Example: 0000-0001-1234-1234
        "#{4.times.map { rand(4 ** 4).to_s.rjust(4,'0') }.join('-')}"
      end

    end

  end


end