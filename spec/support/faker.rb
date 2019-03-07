require 'faker'

LOCALE = 'en'

RSpec.configure do |config|
  config.before(:each) do
    I18n.locale = LocaleFormatter.new(LOCALE, format: :i18n).to_s
    Faker::Config.locale = LocaleFormatter.new(LOCALE, format: :i18n).to_s
  end

  config.after(:each) do
    Faker::Name.unique.clear
    Faker::UniqueGenerator.clear
  end
end
