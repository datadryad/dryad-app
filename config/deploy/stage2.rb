# server-based syntax
# ======================
# Defines a single server with a list of roles and multiple properties.
# You can define all roles on a single server, or split them:

# server 'example.com', user: 'deploy', roles: %w{app db web}, my_property: :my_value
# server 'example.com', user: 'deploy', roles: %w{app web}, other_property: :other_value
# server 'db.example.com', user: 'deploy', roles: %w{db}

set :rails_env, 'stage'
set :passenger_pool, '6'
set :special_login, ' TEST_LOGIN=true '

namespace :deploy do
  before :starting, :stop_delayed_job
  after :finished, :start_delayed_job
  after :finished, :copy_crons_to_shared
end

#set :bundle_env_variables, { 'RAILS_ENV' => 'stage' }

# To override the default host, set $SERVER_HOSTS, e.g.
#    $ SERVER_HOSTS='localhost' bundle exec cap development deploy
set :server_hosts, ENV["SERVER_HOSTS"]&.split(' ') || ['uc3-dryaduix2-stg-2c.cdlib.org']
role %i[app web], fetch(:server_hosts), user: 'dryad'

set :aws_region, 'us-west-2'

#on roles(:all) do |host|
#  puts "setting server host: #{host.hostname}"
#end

#set :passenger_pid, "#{deploy_to}/passenger.pid"
#set :passenger_log, "#{deploy_to}/passenger.log"
#set :passenger_port, "3000"

# role-based syntax
# ==================

# Defines a role with one or multiple servers. The primary server in each
# group is considered to be the first unless any  hosts have the primary
# property set. Specify the username and a domain or IP for the server.
# Don't use `:all`, it's a meta role.

# role :app, %w{deploy@example.com}, my_property: :my_value
# role :web, %w{user1@primary.com user2@additional.com}, other_property: :other_value
# role :db,  %w{deploy@example.com}



# Configuration
# =============
# You can set any configuration variable like in config/deploy.rb
# These variables are then only loaded and set in this stage.
# For available Capistrano configuration variables see the documentation page.
# http://capistranorb.com/documentation/getting-started/configuration/
# Feel free to add new variables to customise your setup.



# Custom SSH Options
# ==================
# You may pass any option but keep in mind that net/ssh understands a
# limited set of options, consult the Net::SSH documentation.
# http://net-ssh.github.io/net-ssh/classes/Net/SSH.html#method-c-start
#
# Global options
# --------------
#  set :ssh_options, {
#    keys: %w(/home/rlisowski/.ssh/id_rsa),
#    forward_agent: false,
#    auth_methods: %w(password)
#  }
#
# The server-based syntax can be used to override options:
# ------------------------------------
# server 'example.com',
#   user: 'user_name',
#   roles: %w{web app},
#   ssh_options: {
#     user: 'user_name', # overrides user setting above
#     keys: %w(/home/user_name/.ssh/id_rsa),
#     forward_agent: false,
#     auth_methods: %w(publickey password)
#     # password: 'please use keys'
#   }
