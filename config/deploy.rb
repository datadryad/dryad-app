# config valid only for current version of Capistrano
lock '~> 3.14'

# set vars from ENV
set :deploy_to, ENV['DEPLOY_TO'] || '/home/ec2-user/deploy'
set :rails_env, ENV['RAILS_ENV'] || 'production'
set :repo_url, ENV['REPO_URL'] || 'https://github.com/datadryad/dryad-app.git'
set :branch, ENV['BRANCH'] || 'main'
set :role, ENV['ROLE'] || 'app'

set :application, 'dryad'
set :default_env, { path: "$PATH" }

# Gets the current Git tag and revision
set :version_number, `git describe --tags`

set :migration_role, fetch(:role)

set :log_level, :debug

if fetch(:role).to_s == 'worker'
  # disable asset compilation
  Rake::Task["deploy:assets:precompile"].clear

  # disable migrations
  Rake::Task["deploy:migrate"].clear
end

# this copies these files over from shared, but only the files that exist on that machine
set :optional_shared_files, %w{
  config/master.key
}
# set :sidekiq_systemctl_user, :system

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
set :puma_service_unit_name, 'puma'
set :puma_systemctl_user, :system


namespace :deploy do
  after :deploy, 'git:version'
  after :deploy, 'cleanup:remove_example_configs'
  after 'deploy:symlink:linked_dirs', 'deploy:files:optional_copied_files'
  on roles(:app), wait: 1 do
    after :deploy, 'sidekiq:restart'
    after 'deploy:published', 'puma:restart_if_exists'
    after 'deploy:published', 'sidekiq:restart_if_exists'
    after 'puma:restart_if_exists', "puma:index_help_center"
  end
end

namespace :git do
  desc "Add the version file so that we can display the git version in the footer"
  task :version do
    on roles(:app, :worker), wait: 1 do
      execute "touch #{release_path}/.version"
      execute "echo '#{fetch :version_number}' >> #{release_path}/.version"
    end
  end
end

namespace :deploy do
  namespace :files do
    task :optional_copied_files do
      on roles(:app, :worker), wait: 1 do
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

namespace :puma do
  task :restart_if_exists do
    on roles(:app) do
      service = fetch(:puma_service_unit_name, "puma")

      if test("[ -f /etc/systemd/system/#{service}.service ]") ||
        test("systemctl list-unit-files | grep -q #{service}.service")
        execute :sudo, :systemctl, :restart, "#{service}.service"
      else
        info "Puma service #{service} not found, skipping restart"
      end
    end
  end
end


namespace :sidekiq do
  task :restart_if_exists do
    on roles(:app) do
      service = fetch(:sidekiq_service_unit_name, "sidekiq")

      if test("[ -f /etc/systemd/system/#{service}.service ]") ||
        test("systemctl list-unit-files | grep -q #{service}.service")
        execute :sudo, :systemctl, :restart, "#{service}.service"
      else
        info "Puma service #{service} not found, skipping restart"
      end
    end
  end
end

namespace :cleanup do
  desc "Remove all of the example config files"
  task :remove_example_configs do
    on roles(:app, :worker), wait: 1 do
      execute "rm -f #{release_path}/config/*.yml.sample"
      execute "rm -f #{release_path}/config/initializers/*.rb.example"
    end
  end
end

task :index_help_center do
  desc  "Index help center"
  on roles(:app) do
    sleep 10
    within release_path do
      with rails_env: fetch(:rails_env) do
        execute :rake, "help_cache"
      end
      execute :yarn, "index:help --silent"
    end
  end
end
