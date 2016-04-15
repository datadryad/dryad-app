# config valid only for current version of Capistrano
lock '3.4.1'

set :application, 'dashv2'
set :repo_url, 'https://github.com/CDLUC3/dashv2.git'

# Default branch is :master -- uncomment this to prompt for branch name
ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp unless ENV['BRANCH']
set :branch, ENV['BRANCH'] if ENV['BRANCH']

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, '/apps/dash2/apps/ui'

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
set :default_env, { path: '/apps/dash2/local/bin:$PATH', 'LOCAL_ENGINES' => 'false' }

# Default value for keep_releases is 5
set :keep_releases, 5

# passenger in gemfile set since we have both passenger and capistrano-passenger in gemfile
set :passenger_in_gemfile, true

# Set whether to restart with touch of touch of tmp/restart.txt.
# There may be difficulties one way or another.  Normal restart may require sudo in some circumstances.
set :passenger_restart_with_touch, false

namespace :deploy do

  desc 'Get list of linked files for capistrano'
  task :my_linked_files do
    on roles(:app) do
      res1 = capture "ls /apps/dash2/apps/ui/shared/config/*.yml -1"
      res1 = res1.split("\n").map{|i| i.match(/config\/[^\/]+$/).to_s }
      res2 = capture "ls /apps/dash2/apps/ui/shared/config/tenants/*.yml -1"
      res2 = res2.split("\n").map{|i| i.match(/config\/tenants\/[^\/]+$/).to_s }
      set :linked_files, (res1 + res2)
    end
  end


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
      execute "cd #{deploy_to}/shared; git reset --hard origin/master; git pull"
    end
  end

  desc 'record branch for engines' #this is so when development restarts it can use the same branch name for engines
  task :record_branch do
    on roles(:app) do
      execute "cd #{deploy_to}/current; touch branch_info; echo '#{fetch(:branch)}' > branch_info"
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
      execute "cd '#{release_path}' && bundle install --without=test"
    end
  end

  desc "clone all engines locally if they don't exist"
  task :clone_engines do
    on roles(:app) do
      %w(stash_engine stash_datacite stash_discovery).each do |engine|
        unless remote_file_exists?("#{deploy_to}/releases/stash_engines/#{engine}")
          execute "mkdir -p #{deploy_to}/releases/stash_engines"
          execute "cd #{deploy_to}/releases/stash_engines; git clone https://github.com/CDLUC3/#{engine}.git; git reset --hard origin/#{my_branch}; git pull"
        end
      end
    end
  end

  def remote_file_exists?(path)
    results = []

    invoke_command("if [ -e '#{path}' ]; then echo -n 'true'; fi") do |ch, stream, out|
      results << (out == 'true')
    end

    results.all?
  end

  #before :restart, :install
  #before :starting, :install
  before :starting, :update_config, :clone_engines
  before :published, :record_branch
  before 'deploy:symlink:shared', 'deploy:my_linked_files'

end
