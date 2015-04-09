$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "stash/harvester/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "harvester"
  s.version     = Stash::Harvester::VERSION
  s.authors     = ["David Moles"]
  s.email       = ["david.moles@ucop.edu"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of Harvester."
  s.description = "TODO: Description of Harvester."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.2.1"

  s.add_development_dependency "sqlite3"
end
