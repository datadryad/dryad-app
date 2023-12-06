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

set :log_level, :debug

# this copies these files over from shared if they exist, but doesn't error if they don't exist (so can be the same in all envs)
set :optional_shared_files, %w{
  config/master.key
  config/credentials/production.key
  config/credentials/stage.key
}

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



# Default value for keep_releases is 5
set :keep_releases, 5

namespace :deploy do
  after :deploy, "git:version"
  after :deploy, "cleanup:remove_example_configs"
  after 'deploy:symlink:linked_dirs', "deploy:files:optional_copied_files"
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

namespace :deploy do
  namespace :files do
    task :optional_copied_files do
      on roles(:app), wait: 1 do
        optional_shared_files = fetch(:optional_shared_files, [])
        optional_shared_files.flatten.each do |file|
          if test "[ -f #{shared_path}/#{file} ]"
            execute "cp #{shared_path}/#{file} #{release_path}/#{file}"
          end
        end
      end
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
