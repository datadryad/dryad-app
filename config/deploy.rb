require "uc3-ssm"

# config valid only for current version of Capistrano
lock '~> 3.14'

# set vars from ENV
set :deploy_to,        ENV['DEPLOY_TO']       || '/dryad/apps/ui'
set :rails_env,        ENV['RAILS_ENV']       || 'production'
set :repo_url,         ENV['REPO_URL']        || 'https://github.com/CDL-Dryad/dryad-app.git'
set :branch,           ENV['BRANCH']          || 'main'

set :application,      'dryad'
set :default_env,      { path: "$PATH" }

# Gets the current Git tag and revision
set :version_number, `git describe --tags`

set :migration_role, :app

# Default value for linked_dirs is []
append :linked_dirs,
       "log",
       "tmp/pids",
       "tmp/cache",
       "tmp/sockets",
       "vendor/bundle",
       "public/system",
       "uploads",
       "reports"

append :linked_files, 'config/notifier_state.json'

# Default value for keep_releases is 5
set :keep_releases, 5

namespace :deploy do
  before :compile_assets, "deploy:retrieve_master_key"
  after :deploy, "git:version"
  after :deploy, "cleanup:remove_example_configs"

  desc 'Retrieve master.key contents from SSM ParameterStore'
  task :retrieve_master_key do
    on roles(:app), wait: 1 do
      ssm = Uc3Ssm::ConfigResolver.new
      master_key = ssm.parameter_for_key('master_key')
      IO.write("#{release_path}/config/master.key", master_key.chomp)
      File.chmod(0600, "#{release_path}/config/master.key")
    end
  end
end

namespace :git do
  desc "Add the version file so that we can display the git version in the footer"
  task :version do
    on roles(:app), wait: 1 do
      execute "touch #{release_path}/.version"
      execute "echo '#{fetch :version_number}' >> #{release_path}/.version"
    end
  end
end

namespace :cleanup do
  desc "Remove all of the example config files"
  task :remove_example_configs do
    on roles(:app), wait: 1 do
      execute "rm -f #{release_path}/config/*.yml.sample"
      execute "rm -f #{release_path}/config/initializers/*.rb.example"
    end
  end
end
