
set :rails_env, 'stage'
set :special_login, ' TEST_LOGIN=true '

# To override the default host, set $SERVER_HOSTS, e.g.
#    $ SERVER_HOSTS='localhost' bundle exec cap development deploy
set :server_hosts, ENV["SERVER_HOSTS"]&.split(' ') || ['v3_stage.datadryad.org', 'sandbox.datadryad.org']
role %i[app web], fetch(:server_hosts), user: 'ec2-user'

