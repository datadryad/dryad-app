# config valid only for current version of Capistrano
lock '3.4.0'

set :application, 'dashv2'
set :repo_url, 'https://github.com/CDLUC3/dashv2.git'

# Default branch is :master -- uncomment this to prompt for branch name
ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, '/dash2/apps/ui'

# Default value for :scm is :git
set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, fetch(:linked_files, []).push(Dir.glob('config/*.yml'), Dir.glob('config/tenants/*.yml')).flatten.uniq

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system')

# Default value for default_env is {}
set :default_env, { path: "/dash2/local/bin:$PATH" }

# Default value for keep_releases is 5
set :keep_releases, 5

# passenger in gemfile set since we have both passenger and capistrano-passenger in gemfile
set :passenger_in_gemfile, true

# Set whether to restart with touch of touch of tmp/restart.txt.
# There may be difficulties one way or another.  Normal restart may require sudo in some circumstances.
set :passenger_restart_with_touch, false

namespace :deploy do

  desc 'Stop Phusion'
  task :stop do
    on roles(:app) do
      if test("[ -f #{fetch(:passenger_pid)} ]")
        execute "cd #{deploy_to}/current; bundle exec passenger stop --pid-file #{fetch(:passenger_pid)}"
      end
    end
  end

  desc 'Start Phusion'
  task :start do
    on roles(:app) do
      within current_path do
        with rails_env: fetch(:rails_env) do
          execute "cd #{deploy_to}/current; bundle exec passenger start -d --environment #{fetch(:rails_env)} --pid-file #{fetch(:passenger_pid)} -p #{fetch(:passenger_port)} --log-file #{fetch(:passenger_log)}"
        end
      end
    end
  end
  # before "deploy:start", "bundle:install"

  # capistrano-passenger should already take care of deploy:restart for us
  #desc 'Restart Phusion'
  #task :restart do
  #  on roles(:app), wait: 5 do
  #    # Your restart mechanism here, for example:
  #    execute :mkdir, '-p', release_path.join('tmp')
  #    execute :touch, release_path.join('tmp/restart.txt')
  #  end
  #end

  desc 'update config repo'
  task :update_config do
    on roles(:app) do
      execute "cd #{deploy_to}/shared; git reset --hard origin/master; git pull"
    end
  end

  #this did not refresh engine gems so no longer called
  desc 'remove engines so they are fresh'
  task :remove_engines do
    on roles(:app) do
      puts "Attempting to remove previous engines to ensure fresh deploy"
      #Dir.chdir "#{deploy_to}/current"
      gems = capture("cd '#{release_path}'; bundle exec gem list | grep stash")
      gems = gems.split("\n").map{|i| i.split(' ').first }
      gems.each do |gem|
        execute "cd '#{release_path}'; bundle exec gem uninstall #{gem}", raise_on_non_zero_exit: false
        execute "cd '#{release_path}'; gem uninstall #{gem}", raise_on_non_zero_exit: false
      end
    end
  end

  #this did not refresh engines without version number changes, so not called
  desc 'update stash engines without version number changes'
  task :update_engines do
    on roles(:app) do
      execute "cd #{deploy_to}/current; bundle update stash_engine; bundle update stash_datacite"
    end
  end

  before :starting, :update_config

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
    execute "cd '#{release_path}' && bundle install  --without=test --no-update-sources"
  end

  before :restart, :install

end


