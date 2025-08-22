
Steps for setting up Dryad on a new EC2 machine with Amazon Linux 2023
======================================================================

- Install an SSH key, so you can login to the machine directly
- git
```
sudo yum update
sudo yum install git
```
- emacs, ack
```
sudo yum install emacs-nox
mkdir emacs
curl "https://raw.githubusercontent.com/yoshiki/yaml-mode/master/yaml-mode.el" >emacs/yaml-mode.el
mkdir bin
curl https://beyondgrep.com/ack-v3.7.0 > ~/bin/ack && chmod 0755 ~/bin/ack
```
- git setup
  - edit the `/.ssh/known_hosts` file to contain the keys from https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints
- install mysql
  - WARNING! MySQL sometimes changes the method for obtaining the RPM. If so, just find the closest available version
    and copy it to the target machine.
  - Get a MySQL 8 "community" RPM from https://dev.mysql.com/downloads/repo/yum/
```
sudo dnf install mysql80-community-release-el9-5.noarch.rpm -y
sudo dnf install mysql-community-server -y
sudo yum install mysql-devel
```
- check out the Dryad code
```
git clone https://github.com/datadryad/dryad-app.git
```
- install ruby
```
sudo yum install -y git-core zlib zlib-devel gcc-c++ patch readline readline-devel libyaml-devel libffi-devel openssl-devel make bzip2 autoconf automake libtool bison perl-core icu libicu-devel
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'eval "$(~/.rbenv/bin/rbenv init - bash)"' >> ~/.bash_profile
# restart the shell
git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build
git -C "$(rbenv root)"/plugins/ruby-build pull
cd dryad-app
sudo yum remove ruby # ensure there is no "default" ruby
rbenv install $(cat .ruby-version)
rbenv global $(cat .ruby-version)
sudo ln -s ~/.rbenv/shims/bundle /usr/bin/bundle
gem update --system --no-user-install

# Replaced by Node and ExcelJS
#gem install libv8 -v '3.16.14.19' --
#gem install therubyracer -v '0.12.3' --

gem install mysql2 -v '0.5.3' -- 
bundle install
```
- update the credentials and deploy script for the specified environment
```
mkdir -p ~/deploy/shared/config/credentials/
# if using a stage or prod environment, put the key in the appropriate place (REPLACE the "stage" with the approppriate key name)
cp stage.key ~/deploy/shared/config/credentials/
cp ~/dryad-app/script/server-utils/deploy_dryad.sh ~/bin/
# EDIT the deploy_dryad.sh to use correct environment name
```
- install node
```
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
. ~/.nvm/nvm.sh
nvm install --lts
nvm install 20.13.1
npm install --global yarn
cd ~/dryad-app
yarn install
npm install --legacy-peer-deps

# add a symlink so other account use the correct node version
sudo su -
ln -s /home/ec2-user/.nvm/versions/node/v20.13.1/bin/node /usr/bin/node
exit
```
- ensure config is correct in startup scripts; add the following to .bashrc
```
. ~/.nvm/nvm.sh
nvm use 20.13.1 >/dev/null
export RAILS_ENV=stage 
```

Database setup
===============

1. Create the database in RDS. When setting up the database in RDS, you must
   crete a parameter group to set the global variable
   `log_bin_trust_function_creators`. Once the parameter group, assign it to the
   database, and once the database has finished updating the config, reboot the
   database to ensure it takes effect.
2. Ensure the appropriate EC2 instances are "connected compute resources" for the database
3. Login to the EC2 instance and create a script to connect to the RDS instance,
   but not a specific database
   - This normally consists of a script and a `.my.cnf` file
   - Copy them from another server, but remove "dryad" from the script
4. Run the script to connect to the RDS instance, then create the database:
   `CREATE DATABASE dryad CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;`
5. Update the script to add the "dryad" database name again


Importing data into AWS RDS database
=====================================

Backups are run using a cron command:
`nice -n 19 ionice -c 3 bundle exec rails dev_ops:backup RAILS_ENV=$1`

To restore from a backup file:
```
# First remove DEFINER statements because RDS doesn't allow the DB users to have
# enough permissions for them to work properly:
sed 's/\sDEFINER=`[^`]*`@`[^`]*`//g' -i myfile.sql

# Then import using the mysql command that you would normally use to run the DB client:
mysql_stg.sh < myfile.sql
```


SOLR setup
============

For general SOLR information, see [solr.md](../solr.md)

SOLR should be installed on a separate machine from the Rails server!

All of these tools are using up to date versions.

To install solr:
```
sudo yum install -y procps gzip tar lsof java wget git
cd ~
wget "https://dlcdn.apache.org/solr/solr/9.7.0/solr-9.7.0.tgz"
tar zxf solr-9.7.0.tgz
cd ~/solr-9.7.0
export SOLR_JETTY_HOST="0.0.0.0"
bin/solr start
bin/solr create -c dryad
```

Before proceeding, ensure the machine's security group allows connections from the world and
verify that the SOLR is visable via the web at http://xxxx:8983

Configure SOLR for Dryad:
```
cd ~/solr-9.7.0
export SOLR_JETTY_HOST="0.0.0.0"
bin/solr stop
cp ~/dryad-app/config/solr_config/* ~/solr-9.7.0/server/solr/dryad/conf/
chmod 775 ~/solr-9.7.0/server/solr/dryad/conf/schema.xml
bin/solr start
```

On the actual Dryad server, force SOLR to reindex:
```
cd ~/deploy/current
bundle exec rails rsolr:reindex
```

Edit the security group for the SOLR server to disallow world access, but allow connections
from IPs of the UI servers that will connect to it.

Reference resources:
- https://solr.apache.org/guide/solr/latest/deployment-guide/securing-solr.html
- https://solr.apache.org/guide/solr/latest/deployment-guide/taking-solr-to-production.html



Setting up for code deployment
==============================

Ensure the machine can SSH to itself to support Capistrano
```
cd ~/.ssh
ssh-keygen # accept default suggestions
cat id_rsa.pub >> authorized_keys
ssh ec2-user@localhost
exit
```

Set up Puma in systemd and get it running
```
# if you have already run deploy_dryad.sh, it can be skipped here
deploy_dryad.sh main
sudo cp ~/dryad-app/documentation/external_services/puma.service /etc/systemd/system/puma.service
sudo nano /etc/systemd/system/puma.service #edit the file to include the correct rails environment
sudo systemctl daemon-reload
sudo systemctl start puma
sudo systemctl enable puma
# check that it is running
sudo systemctl status puma
# check that the homepage renders
curl http://localhost:3000/
```

Set up Apache, which will redirect to Puma and Shibboleth
```
sudo dnf update -y
sudo dnf install -y httpd wget
sudo yum install -y mod_ssl
sudo systemctl start httpd
sudo systemctl enable httpd
sudo systemctl status httpd
ln -s /etc/httpd ~/apache
sudo cp ~/dryad-app/documentation/external_services/datadryad.org.conf ~/apache/conf.d/
sudo touch /var/www/html/index.html
sudo chmod a+w /var/www/html/index.html
echo "<h1>Welcome to MACHINE_NAME</h1>" > /var/www/html/index.html
# Tell SELinux that Apache is allowed to do stuff!
sudo setsebool -P httpd_read_user_content 1
sudo setsebool -P httpd_can_network_connect 1
# UPDATE the settings in datadryad.org.conf to reflect the correct server names
# AND comment out all SSL/Shibboleth settings
sudo nano ~/apache/conf.d/datadryad.org.conf
sudo systemctl restart httpd
# check that the dummy homepage renders at the Apache port
curl http://localhost:80
```

To troubleshoot Apache:
- It may complain that the default configuration file has references to certificate files -- those are fixed below, but for now they can just be commented out
- Apache can "hang" if someone has tried to load the homepage and the SOLR server did not allow connection. In this case, some Apache threads will never finish, and the server will quickly become unresponsive. To fix, ensure that the SOLR server has a security group that accepts connections from the IP address of the Rails/Apache serer. Then kill all "httpd" processes and restart Aapache.


Set up a load balancer to send traffic to the machine
=====================================================

- All of the following steps are in AWS console
- Ensure you are in the proper region -- all of these steps are region dependent
- In Certificate Manager, create a certificate for the target DNS name 
- In EC2, create a target group for the servers that will be balanced
  - Instances
  - HTTP (for testing basic access; will change to HTTPS in next section)
  - IPv4
  - HTTP1
  - Health check = /
- After creating the target group, enable "stickiness" so shibboleth connections will attach to the same server and pass their cookies correctly
  - On the group's detail page, go to Attributes, Edit
  - Turn on stickiness
  - Duration: 10 minutes (don't want it too long, or users will never fail over to the other server)
  - Load balancer generated cookie
- In EC2, create the load balancer and attach the certificate
  - Application Load Balancer
  - Internet-facing
  - IPv4
  - Select all avaiability zones, so you can add new machines without confusing it
  - add listens for both 80 and 443
  - test by copying the load balancer's complex AWS DNS name to the browser
  - 443 listener should forward to the target group
  - 80 listener should redirect to port 443
  - ensure 443 listener has group-level stickiness ON (in addition to the group's internal stickiness; so users can properly authenticate through Shibboleth)
- In Route 53, create a real domain name for the load balancer
  - create an A name that is an alias
  - Alias to Application Load Balancer
  - select the correct region
  - choose the load balancer you just created

To troubleshoot load balancer:
- Enable access logging
  https://docs.aws.amazon.com/elasticloadbalancing/latest/application/enable-access-logging.html
  (when editing the bucket permissions, omit the "aws-account-id/" part)


Set up SSL certificate for Shibboleth support
=============================================

The "main" certificates for Dryad are managed within AWS, using Certificate
Manager. However, Shibboleth requires direct connections between the Identity
provider's `shibd` service and our Apache, which bypass the load balancer. These
connections require Apache to support SSL on its own. We use certificates from
Let's Encrypt for these direct connections. (Note that there is a third
certificate used for our `shibd` to communicate with InCommon. See [the
Shibboleth docs](../shibboleth/README.md) for details.)

In a load-balanced system, only create the certificate on one machine, and copy to the others.

```
# Adapted from https://certbot.eff.org/instructions?ws=apache&os=pip
sudo dnf install -y augeas-libs
sudo python3 -m venv /opt/certbot/
sudo /opt/certbot/bin/pip install --upgrade pip
sudo /opt/certbot/bin/pip install certbot certbot-apache
sudo ln -s /opt/certbot/bin/certbot /usr/bin/certbot
sudo certbot certonly --apache #If it complains about port 80, change the port at the top of datadryad.org.conf (temporarily) and restart apache
sudo cp /etc/letsencrypt/live/sandbox.datadryad.org/fullchain.pem /etc/pki/tls/certs/letsencrypt.crt
sudo cp /etc/letsencrypt/live/sandbox.datadryad.org/privkey.pem /etc/pki/tls/private/letsencrypt.key
```

To get Apache using the new certificates:
1. Update datadryad.org.conf to use the certificate files (and the 443 port at the top)
2. Restart Apache
3. In AWS, rebuild the Target Group (as in the section above), using HTTPS setting instead of HTTP.

Verify the certificates and check expiration dates (on all servers)
```
curl --insecure -vvI https://localhost 2>&1 | awk 'BEGIN { cert=0 } /^\* SSL connection/ { cert=1 } /^\*/ { if (cert) print }'
```


To renew the LetsEncrypt certificates
--------------------------------------

1. Set load balancer to only point to the first server, which is the one with certbot installed
2. Ensure the config includes both port 80 and port 443
```
sudo emacs apache/conf.d/datadryad.org.conf
sudo systemctl restart httpd
```
3. Create and apply new certificate
```
sudo certbot certonly --apache
```
4. Copy the keys to the correct locations
```
sudo cp /etc/letsencrypt/live/sandbox.datadryad.org/fullchain.pem /etc/pki/tls/certs/letsencrypt.crt
sudo cp /etc/letsencrypt/live/sandbox.datadryad.org/privkey.pem /etc/pki/tls/private/letsencrypt.key
```
5. Restart apache to use new certs
```
sudo systemctl restart httpd
```
6. Copy certs to other servers and restart their Apaches too
7. Verify certificates (on all servers)
```
curl --insecure -vvI https://localhost 2>&1 | awk 'BEGIN { cert=0 } /^\* SSL connection/ { cert=1 } /^\*/ { if (cert) print }'
```


Set up shibboleth service provider
==================================

See instructions in [the shibboleth directory](../shibboleth/README.md).


Set up other system services
======================================

Set up systemd services that need to remain running
```
sudo cp ~/dryad-app/documentation/external_services/delayed_job.service /etc/systemd/system/delayed_job.service
sudo nano /etc/systemd/system/delayed_job.service #edit the file to include the correct rails environment
sudo cp ~/dryad-app/documentation/external_services/status_updater.service /etc/systemd/system/status_updater.service
sudo nano /etc/systemd/system/status_updater.service #edit the file to include the correct rails environment

sudo systemctl daemon-reload
sudo systemctl start status_updater
sudo systemctl enable status_updater
sudo systemctl start delayed_job
sudo systemctl enable delayed_job
# check that they are running
sudo systemctl status delayed_job
sudo systemctl status status_updater
```

Set up crons
======================================
Set up cron jobs using systemd services. Documentation in [here](../../cron/README.md)


Troubleshooting
================

Load balancer intermittently reports server as unhealthy
- Verify that the server can reach SOLR, using `curl` with the SOLR server's base address from
  `config/blacklight.yml` -- Note that receiving an error is fine, since this
  is only the base URL. If the call hangs, there is likely a problem with the
  SOLR server's security group not letting the Rails server connect.

Set up AWS CloudWatch Agent
======================================

AWS CloudWatch Agent is installed on all servers and is used for:
- Serving metrics related to disk usage.
- Stream log files to Cloudwatch

Check [here](./amazon_cloudwatch_config.md) CloudWatch Agent configuration details and examples.

Set up Anubis
======================================

Detailed Anubis documentation can be found [here](https://anubis.techaro.lol/).
Anubis is installed on all servers and used as a bridge between Apache and Puma.

Install requirements:
--------------------------------------
- Go language - version 1.24.2 or newer
- `brotli.x86_64` package
```
cd ~
sudo yum install brotli.x86_64
wget https://dl.google.com/go/go1.24.2.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.24.2.linux-amd64.tar.gz
rm go1.24.2.linux-amd64.tar.gz
```

Update `~/.bashrc` and add `export PATH=$PATH:/usr/local/go/bin`.

Test the installation with `go version`.

Download and setup Anubis
--------------------------------------
Download and build
```
cd ~
git clone https://github.com/TecharoHQ/anubis.git
cd anubis/

make prebaked-build

make deps
npm install --save-exact --save-dev esbuild
./node_modules/.bin/esbuild --version
make assets
make build
```

Change configuration files 

`vim run/anubis@.service` and update with [this](./anubis@.service)

`vim run/default.env` and add `POLICY_FNAME=/home/ec2-user/anubis/data/botPolicies.json`

Create systemd service
```
cd ~/anubis/
sudo install -D ./run/anubis@.service /etc/systemd/system
sudo systemctl enable anubis@default.service
sudo systemctl start anubis@default.service
sudo systemctl status anubis@default.service
```

Update Apache configuration
--------------------------------------
Add anubis cluster ando point apache to it
```
sudo vim ~/apache/conf.d/datadryad.org.conf
apache_restart.sh
```

```
RewriteRule ^/(.*)$ balancer://anubis_cluster%{REQUEST_URI} [P,QSA,L,NE]

# Set X-Real-IP header
RequestHeader set X-Real-IP "%{REMOTE_ADDR}s"

<Proxy balancer://anubis_cluster>
  BalancerMember http://localhost:8923 max=64 acquire=10 timeout=600 Keepalive=On
</Proxy>
```

Install Google Chrome Driver
======================================

In order to be able to generate PDF files with Grover gem we need chrome driver.
```
cd /tmp
wget https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
sudo yum localinstall google-chrome-stable_current_x86_64.rpm
```

Extending a disk on EC2
========================

In the console, select the disk, modify, and give it the new size.

```
# See the size of the disk and partitions
sudo lsblk

# Grow a partition to use the new space (not required if there is no partition)
sudo growpart /dev/nvme0n1 1

# Verify that it grew (not required if there is no partition)
sudo lsblk

# See where the partition is mounted
df -hT

# Extend the filesystem to use the full partition
sudo xfs_growfs -d <filesystem location>
```
