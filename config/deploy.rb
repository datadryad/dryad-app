# config valid only for current version of Capistrano
lock '3.4.1'

set :application, 'dryad'
set :repo_url, 'https://github.com/CDL-Dryad/dryad.git'

# Default branch is :master -- uncomment this to prompt for branch name
ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp unless ENV['BRANCH']
set :branch, ENV['BRANCH'] if ENV['BRANCH']

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, '/apps/dryad/apps/ui'

# Default value for :scm is :git
set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
#set :linked_files, fetch(:linked_files, []).push(Dir.glob('config/*.yml'), Dir.glob('config/tenants/*.yml')).flatten.uniq
#set :linked_files, fetch(:linked_files, []).push(invoke 'deploy:my_linked_files').flatten.uniq

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle',
                                               'public/system', 'uploads')

# Default value for default_env is {}
# set :default_env, { path: '/apps/dash2/local/bin:$PATH', 'LOCAL_ENGINES' => 'false' }
set :default_env, { path: '/apps/dryad/local/bin:$PATH' }

# Default value for keep_releases is 5
set :keep_releases, 5

# passenger in gemfile set since we have both passenger and capistrano-passenger in gemfile
set :passenger_in_gemfile, true

# Set whether to restart with touch of touch of tmp/restart.txt.
# There may be difficulties one way or another.  Normal restart may require sudo in some circumstances.
set :passenger_restart_with_touch, false

set :passenger_restart_options, -> { "#{deploy_to} --ignore-passenger-not-running" }
set :passenger_environment_variables, {}

set :passenger_pid, "#{deploy_to}/passenger.pid"
set :passenger_log, "#{deploy_to}/passenger.log"
set :passenger_port, "3000"

TAG_REGEXP = /^[v\d\.]{3,}.*$/.freeze

namespace :deploy do

  desc 'Get list of linked files for capistrano'
  task :my_linked_files do
    on roles(:app) do
      res1 = capture "ls /apps/dryad/apps/ui/shared/config/*.yml -1"
      res1 = res1.split("\n").map{|i| i.match(/config\/[^\/]+$/).to_s }
      res2 = capture "ls /apps/dryad/apps/ui/shared/config/tenants/*.yml -1"
      res2 = res2.split("\n").map{|i| i.match(/config\/tenants\/[^\/]+$/).to_s }
      set :linked_files, (res1 + res2)
    end
  end

  desc 'Restart Phusion'
  task :restart do
    on roles(:app), wait: 5 do
      # Your restart mechanism here, for example:
      invoke 'deploy:stop'
      invoke 'deploy:start'
    end
  end

  desc 'update config repo'
  task :update_config do
    on roles(:app) do
      my_branch = fetch(:branch, 'development')
      my_branch = "origin/#{my_branch}" unless my_branch.match(TAG_REGEXP) #git acts differently with tags (regex for version #s)
      execute "cd #{deploy_to}/shared; git fetch --tags; git fetch --all; git reset --hard #{my_branch}"
    end
  end

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
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

  desc "clone all engines locally if they don't exist"
  task :clone_engines do
    on roles(:app) do
      unless test("[ -d #{deploy_to}/releases/stash ]")
        execute "cd #{deploy_to}/releases; git clone https://github.com/CDL-Dryad/dryad.git"
      end
    end
  end

  desc 'update local engines to get around requiring version number changes in development'
  task :update_local_engines do
    on roles(:app) do
      my_branch = fetch(:branch, 'development')
      my_branch = "origin/#{my_branch}" unless my_branch.match(TAG_REGEXP) #git acts differently with branch vs tag
      execute "cd #{deploy_to}/releases/stash; git fetch --tags; git fetch --all; git reset --hard #{my_branch}"
    end
  end

  #Rake::Task["start"].clear_actions
  desc 'Start Phusion'
  task :start do
    on roles(:app) do
      within current_path do
        with rails_env: fetch(:rails_env) do
          execute "cd #{deploy_to}/current; bundle install --deployment"
          execute "cd #{deploy_to}/current; bundle exec passenger start -d --environment #{fetch(:rails_env)} "\
              "--pid-file #{fetch(:passenger_pid)} -p #{fetch(:passenger_port)} "\
              "--log-file #{fetch(:passenger_log)} --pool-idle-time 86400"
        end
      end
    end
  end

  #Rake::Task["stop"].clear_actions
  desc 'Stop Phusion'
  task :stop do
    on roles(:app) do
      if test("[ -f '#{fetch(:passenger_pid)}' ]")
        execute "cd #{deploy_to}/current; bundle exec passenger stop --pid-file #{fetch(:passenger_pid)}"
      end
    end
  end

  Rake::Task["cleanup"].clear_actions
  desc "Clean up old releases"
  task :cleanup do
    on release_roles :all do |host|
      releases = capture(:ls, "-xtr", releases_path).split.keep_if{|i| i.match(/^[0-9]+$/) }
      if releases.count >= fetch(:keep_releases)
        info t(:keeping_releases, host: host.to_s, keep_releases: fetch(:keep_releases), releases: releases.count)
        directories = (releases - releases.last(fetch(:keep_releases)))
        if directories.any?
          directories_str = directories.map do |release|
            releases_path.join(release)
          end.join(" ")
          execute :rm, "-rf", directories_str
        else
          info t(:no_old_releases, host: host.to_s, keep_releases: fetch(:keep_releases))
        end
      end
    end
  end

  before :starting, :update_config
  before :starting, :clone_engines
  after :started, :update_local_engines
  before 'deploy:symlink:shared', 'deploy:my_linked_files'
  #after :published, :update_local_engines

end
