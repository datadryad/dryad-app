# server-based syntax
# ======================
# Defines a single server with a list of roles and multiple properties.
# You can define all roles on a single server, or split them:

# server 'example.com', user: 'deploy', roles: %w{app db web}, my_property: :my_value
# server 'example.com', user: 'deploy', roles: %w{app web}, other_property: :other_value
# server 'db.example.com', user: 'deploy', roles: %w{db}

set :rails_env, 'production'
set :passenger_pool, '12'

#set :bundle_env_variables, { 'RAILS_ENV' => 'stage' }

# To override the default host, set $SERVER_HOSTS, e.g.
#    $ SERVER_HOSTS='localhost' bundle exec cap development deploy
set :server_hosts, ENV["SERVER_HOSTS"]&.split(' ') || ['datadryad.org']
role %i[app web], fetch(:server_hosts), user: 'dryad'

set :aws_region, 'us-west-2'


namespace :deploy do
  before :start, :setup_cron
  after :finished, :copy_crons_to_shared
end
