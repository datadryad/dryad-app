
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
git clone https://github.com/CDL-Dryad/dryad-app.git
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
gem install libv8 -v '3.16.14.19' --
gem install therubyracer -v '0.12.3' --
gem install mysql2 -v '0.5.3' -- 
bundle install
```
- update the credentials and deploy script for the specified environment
```
mkdir -p ~/deploy/shared/config/credentials/
# if using a stage or prod environment, put the key in the appropriate place (REPLACE the "v3_stage" with the approppriate key name)
cp v3_stage.key ~/deploy/shared/config/credentials/
cp ~/dryad-app/script/server-utils/deploy_dryad.sh ~/bin/
# EDIT the deploy_dryad.sh to use correct environment name
```
- install node
```
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
. ~/.nvm/nvm.sh
nvm install --lts
nvm install 16.20.2
npm install --global yarn
cd ~/dryad-app
yarn install
npm install --legacy-peer-deps
```
- ensure config is correct in startup scripts; add the following to .bashrc
```
. ~/.nvm/nvm.sh
nvm use 16.20.2 >/dev/null
export RAILS_ENV=v3_stage 
```
- compile components
```
bin/webpack
bundle exec rails webpacker:compile
```
- run rails
```
cd ~/dryad-app
rails s
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

All of these tools are outdated. To make SOLR work with Dryad's old
GeoBlacklight, we need to use SOLR 7 or before. SOLR 7 requires very old Java,
such as 1.8.

To install solr:
```
sudo yum install java-1.8.0-amazon-corretto
wget "https://archive.apache.org/dist/lucene/solr/7.7.3/solr-7.7.3.tgz"
tar zxf solr-7.7.3.tgz
cd ~/solr-7.7.3
export SOLR_JETTY_HOST="0.0.0.0"
bin/solr start
bin/solr create  -c geoblacklight
```

Before proceeding, ensure the machine's security group allows connections from the world and
verify that the SOLR is visable via the web at http://xxxx:8983

Configure SOLR for Dryad:
```
cd ~/solr-7.7.3
export SOLR_JETTY_HOST="0.0.0.0"
bin/solr stop
cp ~/dryad-app/config/solr_config/* ~/solr-7.7.3/server/solr/geoblacklight/conf/
chmod 775 ~/solr-7.7.3/server/solr/geoblacklight/conf/schema.xml
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
curl http://localhost:3000/stash
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
sudo chmod a+w /var/www/html/index.html
echo "<h1>Welcome to MACHINE_NAME</h1>" > /var/www/html/index.html
# UPDATE the settings in datadryad.org.conf to reflect the correct server names
sudo systemctl restart httpd
# check that the homepage renders at the Apache port
curl http://localhost:80/stash
```

To troubleshoot Apache:
- Apache can "hang" if someone has tried to load the homepage and the SOLR server did not allow connection. In this case, some Apache threads will never finish, and the server will quickly become unresponsive. To fix, ensure that the SOLR server has a security group that accepts connections from the IP address of the Rails/Apache serer. Then kill all "httpd" processes and restart Aapache.

Set up a load balancer to send traffic to the machine
- All of the following steps are in AWS console
- Ensure you are in the proper region -- all of these steps are region dependent
- In Certificate Manager, create a certificate for the target DNS name 
- In EC2, create a target group for the servers that will be balanced
- In EC2, create the load balancer and attach the certificate
  - Application Load Balancer
  - Internet-facing
  - IPv4
  - Select all avaiability zones, so you can add new machines without confusing it
  - add listens for both 80 and 443
  - test by copying the load balancer's complex AWS DNS name to the browser
  - 443 listener should forward to the target group
  - 80 listener should redirect to port 443
- In Route 53, create a real domain name for the load balancer
  - create an A name that is an alias
  - Alias to Application Load Balancer
  - select the correct region
  - choose the load balancer you just created

To troubleshoot load balancer:
- Enable access logging
  https://docs.aws.amazon.com/elasticloadbalancing/latest/application/enable-access-logging.html
  (when editing the bucket permissions, omit the "aws-account-id/" part)


## Set up shibboleth service provider
```
sudo yum update -y
```

- create a repo file for the shibboleth package under `/etc/yum.repos.d/shibboleth.repo` and include the contents from this link (choose Amazon Linux 2023 from the first dropdown and hit generate)
- run `sudo yum install shibboleth.x86_64` (make sure the .x86_64 version is used)
- enable the service: `sudo systemctl enable shibd.service`
- run via `sudo systemctl start shibd`

Configuration
- Update the contents of `/etc/shibboleth/shibboleth2.xml`
  - make sure the email address is set to `admin@datadryad.org`
- Update the apache configs (uncomment relevant sections)
  - under `/etc/httpd/conf.d`, there is a `shib.conf`, as well as a `datadryad.org.conf` 
  - look out for the `cgi-bin` section  


Set up other system services and crons
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
