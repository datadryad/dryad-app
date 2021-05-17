require 'json'

# config valid only for current version of Capistrano
lock '~> 3.14'

set :application, 'dryad'
set :repo_url, 'https://github.com/CDL-Dryad/dryad-app.git'

# Default branch is :main -- uncomment this to prompt for branch name
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp unless ENV['BRANCH']
# Actually, use development for default branch
set :branch, 'development'
set :branch, ENV['BRANCH'] if ENV['BRANCH']

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, '/apps/dryad/apps/ui'

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# This syntax doesn't work well for getting multiple files out of a directory, so
# it is better to add linked_files through the my_linked_files below.
# set :linked_files, fetch(:linked_files, []).push('fileA.txt', 'config/fileB.txt')

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle',
                                               'public/system', 'uploads')

# Default value for default_env is {}
# set :default_env, { path: '/apps/dash2/local/bin:$PATH', 'LOCAL_ENGINES' => 'false' }
set :default_env, { path: '/apps/dryad/local/bin:$PATH' }

# Default value for keep_releases is 5
set :keep_releases, 5

# Run migrations on the app server, otherwise they only run on the db role server
# See https://github.com/capistrano/rails/issues/78
set :migration_role, :app

TAG_REGEXP = /^[v\d\.]{3,}.*$/.freeze

namespace :debug do
  desc 'Print ENV variables'
  task :env do
    on roles(:app), in: :sequence, wait: 5 do
      execute :whoami
      execute :printenv
    end
  end

  # These are useful for testing the server setup
  # see https://capistranorb.com/documentation/faq/why-does-something-work-in-my-ssh-session-but-not-in-capistrano/
  task :query_interactive do
    on roles(:app) do
      info capture("[[ $- == *i* ]] && echo 'Interactive' || echo 'Not interactive'")
    end
  end

  task :query_login do
    on roles(:app) do
      info capture("shopt -q login_shell && echo 'Login shell' || echo 'Not login shell'")
    end
  end
end

namespace :deploy do

  desc 'Get list of linked files for capistrano'
  task :my_linked_files do
    on roles(:app) do
      res1 = capture "ls /apps/dryad/apps/ui/shared/config/*.key -1"
      res1 = res1.split("\n").map{|i| i.match(/config\/[^\/]+$/).to_s }
      set :linked_files, (res1)
    end
  end
  
  desc 'Restart Puma???'
  task :restart do
    on roles(:app), wait: 5 do
      # Your restart mechanism here, for example:
      invoke 'deploy:stop'
      invoke 'deploy:start'
    end
  end

  desc 'stop delayed_job'
  task :stop_delayed_job do
    on roles(:app) do
      execute "cd #{deploy_to}/current; RAILS_ENV=#{fetch(:rails_env)} bundle exec bin/delayed_job -n 3 stop"
    end
  end

  desc 'start delayed_job'
  task :start_delayed_job do
    on roles(:app) do
      execute "cd #{deploy_to}/current; RAILS_ENV=#{fetch(:rails_env)} bundle exec bin/delayed_job -n 3 start"
    end
  end


  desc 'copy crons to the shared directory where the schedule crons expect them'
  task :copy_crons_to_shared do
    # This was going to be a symlink into current, but we don't want to put the shared/cron directory within
    # current since it contains a backup directory of our database. It would then multiply
    # the backups across every version when we deploy and make us run out of disk space.
    #
    # When the crons are changed in Puppet for the new path, we can remove this copying script.
    on roles(:app) do
      execute "mkdir -p /apps/dryad/apps/ui/shared/cron"
      execute "cp /apps/dryad/apps/ui/current/cron/* /apps/dryad/apps/ui/shared/cron"
    end
  end

  after :restart, :clear_cache do
    on roles(:app), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

  desc "run bundle install and ensure all gem requirements are met"
  task :install do
    on roles(:app) do
      execute "cd '#{release_path}' && bundle install --without=test --deployment"
    end
  end

  desc 'Setup the shell script that is executed by Cron for the environment'
  task :setup_cron do
    on roles(:app) do
      # Create sub directories
      execute "mkdir -p #{deploy_to}/shared/cron/backups"
      execute "mkdir -p #{deploy_to}/shared/cron/logs"
      # Make the shell scripts executable
      execute "chmod 750 #{deploy_to}/shared/cron/*.sh"
    end
  end

  before 'deploy:symlink:shared', 'deploy:my_linked_files'

  before :compile_assets, :env_setup

  desc 'Setup ENV Variables'
  task :env_setup do
    on roles(:app), wait: 1 do
      json = capture ("aws ssm get-parameter --name \"#{fetch(:ssm_root_path)}master_key\" --region \"#{fetch(:aws_region)}\"")
      json = JSON.parse(json)
      master_key = json['Parameter']['Value']

      info "Uploading master key to #{release_path}/config/master.key"
      upload! StringIO.new(master_key), "#{release_path}/config/master.key"
    end
  end
end
