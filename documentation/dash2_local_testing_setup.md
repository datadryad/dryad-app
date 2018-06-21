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
file to allow modifications to its generally very strict (and sometimes unintelligent) checking.  It also
makes changes to its software and configuration on a fairly frequent basis.  Different versions
of Rubocop or for different target Ruby versions
will bring up different suggestions or even bring in Rubocop configuration syntax changes.  We've also tried
to keep rubocop versions the same across different components as there is some inheritance of settings.

You will probably want to run Rubocop outside of the test suite but use the same environment settings as used
by the test suite.  It's very common to run *rubocop -a* which will auto-fix (mostly) clear-cut conventions such as
spacing irregularities or similar items.  It's also nice to be able to fix problems and re-run rubocop
separately from running the tests, iterating until all style suggestions are fixed or acknowledged.

By appending *bundle exec* to a Ruby command in context of an application (or gem or engine), it runs that command
in the environment defined for use by that application.  It uses the external gems (libraries) and versions indicated in
the Gemfile, pulled in by dependencies and locked in place by the Gemfile.lock.  It should keep some random problems
from occuring because of version differences between a gem locally instaled on the computer and an
application-specific gem.

The hidden .ruby-version file in the root of an application (or engine or gem) does something a little similar to Bundler
but instead of locking a known set of gems and versions in place, it tells the version of Ruby that the application
expects to use.  Software such as rbenv or rvm will read this file and can do things such as automatically switching
to using that version of Ruby when cd-ing to that directory (or prompting to install the expected version of Ruby).
Also, some IDEs will look at the file for tailoring suggestions to a specific version of Ruby.

Rake is a way to define utility or other tasks that might be run (note the similar name to Make).  The default task for our
components is to run tests.  You can define other rake tasks and specify a task when running Rake to do other things.
