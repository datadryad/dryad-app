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
        "#{Faker::Number.decimal(2, 4)}/#{Faker::Lorem.word}.#{Faker::Alphanumeric.alphanumeric 5}"
      end

    end

  end


end