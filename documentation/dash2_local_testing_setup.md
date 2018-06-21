# Setting up local testing

Running tests locally on a development machine means an easier time writing and developing tests, running an individual test and
also not needing to wait for travis.ci to run all tests in order to get results.

## Install MySQL if not installed

```
# installing MySQL in an Ubuntu Linux distro, make note of any root password you set while installing
sudo apt-get install mysql-server mysql-client libmysqlclient-dev

# make sure MySQL is started
sudo service mysql start

# Depends how the MySQL installs, how it lets you in. If not working, try with and without sudo or with password
# to be sure you can get into mysql
sudo mysql -u root

mysql> CREATE USER 'travis'@'%';

# If you need to use sudo to get into mysql as a root user, please see instructions at 
# https://askubuntu.com/questions/766334/cant-login-as-mysql-user-root-from-normal-user-account-in-ubuntu-16-04/801950
# to allow MySQL root access to the test/dev environment without having to use sudo.  Note, MySQL root access should
# be secured on production servers and not left open.

# the travis_prep.sh script below assumes it can access MySQL root user without a password (or sudo) for setting up a testing environment.
```

## Get Oracle JRE installed if needed

The OpenJRE did not work correctly with SOLR when I tested, so you may need to install an Oracle runtime.

```
sudo add-apt-repository ppa:webupd8team/java
sudo apt-get update

sudo apt-get install oracle-java8-installer

# this isn't for Java, but while you're in here, install the Chromium browser which gets automated for testing the UI
sudo apt install -y chromium-browser
```

## Setting up and running tests

It's usually convenient to run tests just on the part of the application where you have changed code.  For example
within an engine or in the main app for overall testing through the UI.

Each component has a *travis-prep.sh* script for setting up the database for testing that component and it only needs to be run once
if you continue to use the same test database.

For example, to set up and run the tests in the stash_engine:

```
cd stash/stash_engine

# travis_prep only needs to be done the first time you use a database and sets it up for testing this component
./travis_prep.sh

# this command runs the default rake task, which will run all tests for the component
bundle exec rake
```

## Notes about Rubocop, .ruby-version, Bundler and Rake

One component of the test suite runs Rubocop which is a style and convention checker.  It uses a configuration
file to allow modifications to its generally very strict checking.  It also makes changes to its software and
configuration on a fairly frequent basis.  Different versions of Rubocop or for different target Ruby versions
will bring up different suggestions.

Because it
