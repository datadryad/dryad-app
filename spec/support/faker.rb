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
        "10.#{Faker::Number.number(4)}/#{Faker::Alphanumeric.alphanumeric(4)}.#{Faker::Alphanumeric.alphanumeric(5)}"
      end

      def orcid
        # Example: 0000-0001-1234-1234
        Array.new(4) { rand(4**4).to_s.rjust(4, '0') }.join('-')
      end

      def issn
        # Example: 0317-8471 OR 1050-124X
        val = Array.new(2) { rand(4**4).to_s.rjust(4, '0') }.join('-')
        (%i[0 1].include?(val.last) ? val.sub(/[\d]$/, 'X') : val)
      end

    end

  end

end
