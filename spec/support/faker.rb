require 'faker'

LOCALE = 'en'.freeze

RSpec.configure do |config|
  config.after(:each) do
    Faker::Name.unique.clear
    Faker::UniqueGenerator.clear
  end
end
