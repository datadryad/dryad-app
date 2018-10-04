require 'factory_bot'
require 'pathname'
require 'byebug'

# I had a horrible time with FactoryBot, probably because our super mega engine stack is unusual
# It likes to load factories multiple times or never and had to require in individual spec files and
# use FactoryBot.find_definitions in the spec files where it is needed

# see also https://stackoverflow.com/questions/9300231/factory-already-registered-user-factorygirlduplicatedefinitionerror for more fun

# for a while it was having trouble finding the path for our definitions, this helped, may need again later.
# base_path = File.join(StashApi::Engine.root, 'spec/factories')
# definition_paths = [base_path] + Pathname.new(base_path).children.select(&:directory?).map(&:to_s)

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  FactoryBot.reload # this seems to fix the FactoryBot find_definitions problem about stuff already loaded
  # otherwise if we need to load the definitions, maybe could catch the error instead and ignore reloading them
end
