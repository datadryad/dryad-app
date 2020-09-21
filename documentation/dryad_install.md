# Dryad installation (v0.0.2)

The Dryad application is made of a number of parts intended to keep it more flexible and to separate concerns so that parts can be replaced with new metadata and other engines to customize it.  Some basic information about the project and architechiture is available at [the Dash Website](https://dash.ucop.edu/stash/about), but this document focuses on getting Dash up and running for development.

## The ingredients

You'll need the following parts installed and configured on a (local) UI development server to do development on the full UI application.  Don't worry, there are more detailed installation instructions in other sections below and this is meant to give an overview of the larger dependencies to configure.

- (Recommended) A ruby version manager such as [rbenv](https://github.com/rbenv/rbenv) or [rvm](https://rvm.io/)
- The [bare Dryad application](https://github.com/CDL-Dryad/dryad-app) cloned from github

You'll also need the following components installed either on the same server or on separate servers for all the application features to work:

- MySQL (with the database specified in the database.yml created and using utf8mb4 character set by default)
- SOLR (with a geoblacklight schema and core installed)
- A storage repository that supports SWORD will be needed to submit documents to the repository and even with SWORD support, the code may need some customization for others besides the Merritt repository.
- A DOI minting service such as EZID to mint DOIs.

The application also requires some means to log in outside of a development environment. You'd want to configure a log in method for each application tenant from these:

- Google login
- Shibboleth login
- ORCID login (coming soon and required for ORCID lookup in the metadata page)

## Installing the code and a base config

Open a (bash) shell and type these commands inside a directory where you want to work with this code. These will clone the development code and an example config.

```
git clone https://github.com/CDL-Dryad/dryad-app
```

You should end up with a directory structure that looks like this one.

```
├── dryad
|   ├── config
|   └── dryad-config-example
└── stash
    ├── stash-harvester
    ├── stash-merritt
    ├── stash-sword
    ├── stash-wrapper
    ├── stash_datacite
    ├── stash_discovery
    └── stash_engine
```

Most of the configuration can be left as default. Items to check before first launch:
1. dryad-config/database.yml
2. dryad-config/app_config.yml, particularly the ORCID key and secret

## Installing MySQL and Solr

### MySQL

The procedure to install MySQL and Solr vary from one operating system to another, but this guide shows a way to configure it in Ubuntu linux:

```
# installing MySQL in an Ubuntu Linux distro, make note of the root password you set while installing
sudo apt-get install mysql-server mysql-client libmysqlclient-dev

# make sure MySQL is started
sudo service mysql start

# connect to mysql, note the <username> is probably root in a new installation, and the password is probably blank
mysql -u <username> -p

# if the above doesn't work, try
sudo mysql -u root



# create the dash database
CREATE DATABASE dryad CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

# add a user to the database
CREATE USER 'travis'@'%';

# grant the user privileges
GRANT ALL PRIVILEGES ON dryad . * TO 'travis'@'%';
FLUSH PRIVILEGES;

# To exit the MySQL client, type *exit* or press ctrl-d

```

Now edit the dryad-config/config/database.yml file to fill in the *dashuser* and password you set above in the development environment for that configuration file.

### Solr
Solr requires a Java runtime.  Try *java -version* and if it says that "java can be found in the following packages" rather than giving you a version you probably need to install java with a command like *sudo apt-get install default-jre* .

[This readme contains updated information](../config/solr_config/README.md)


<br>Make sure Solr is working by going to  [http://localhost:8983](http://localhost:8983). You should see a Solr admin page.

![Solr screen](images/solr1.png)

Verify Solr is set up correctly from the Admin UI:

1. Choose the geoblacklight core from the core selector list.<br>![core selctor](images/solr2.png)

2. You can then click the *query* sidebar tab and scroll down to the bottom of the form to submit a blank query.  While the document will not return any results yet because there are no documents in SOLR, you should see it execute and you can verify that Solr queries are running.<br>![query test](images/solr3.png)

<br>(Optional, but recommended) Add a sample record to match the sample database record (see below).

1. Click the *Documents* tab on the left side.<br>![Documents](images/solr4.png)

2. Find the file *dryad-config/sample\_data/sample\_record.json* in the dryad-config repo.  Open the file in a text editor, select all the text and copy it.

3. Paste the text into the *Document(s)* box on the page.<br>![json pasted](images/solr5.png)
4. Click *Submit Document* and be sure it shows a status of success.<br>![success status](images/solr6.png)

## Getting the Rails application running

I'd *strongly* recommend installing [rbenv](https://github.com/rbenv/rbenv) for a local development asenvironment as a way to manage Ruby versions.  Follow the installation instructions given on the rbenv site to install it, but make sure the `rbenv init` command is run in every shell (e.g., add it to .bashrc). Install the [Ruby build plugin](https://github.com/rbenv/ruby-build#readme) to make it easy to install different Ruby versions as needed.

```
# make sure some basic libraries are installed that are probably required later (Ubuntu example)
sudo apt-get install libxml2 libxml2-dev patch curl

cd dryad
rbenv install $(cat .ruby-version) # installs the ruby-version set in the .ruby-version file

# update your rubygems version
gem update --system

# install bundler to handle gem dependencies
gem install bundler:2.1.4
```

**If you are running on OSX, ensure some gems are compatible with the system:**
```
xcode-select --install
gem install libv8 -v '3.16.14.19' -- --with-system-v8
gem install therubyracer -v '0.12.3' -- --with-v8-dir=/usr/local/opt/v8@3.15
gem install mysql2 -v '0.5.3' -- --with-ldflags=-L/usr/local/opt/openssl/lib --with-cppflags=-I/usr/local/opt/openssl/include
```

For all operating systems, continue:
```
# now install the gem libraries needed for the application
bundle install

# run the migrations to set up the database tables
bundle exec rails db:migrate

# start your rails server for local development
rails s
```

If you want to view sample data, then insert a sample record into the database (recommended).

```
# connect to mysql, note the <username> is probably root in a new installation
mysql -u <username> -p

# Use the following two lines.
USE dash;
source ../dryad-config/sample_data/sample_record.sql;

# To exit the MySQL client, type *exit* or press ctrl-d
```

To configure where the search enterface draws its data from, modify the dryad app config/blacklight.yml to change the endpoint for the development server.  When running locally, the default server is development.

## Creating the System user

Go into Rails console, and create the default user.

```
bundle exec rails console
u=StashEngine::User.create(first_name: 'Dryad', last_name: 'System', id: 0)
```

## Testing basic functionality

### Explore the datasets
Open your web browser and go to [http://localhost:3000](http://localhost:3000) to see the homepage.

The *Explore Data* link will allow you to search and view your dataset, if you imported a sample record.

![Explore Splash](images/explore1.png)<br><br>
![Search Results](images/explore2.png)<br><br>
![Dataset Page](images/explore3.png)

### Enter dataset metadata, upload files and preview the landing page

After you log in, you will be able to start entering metadata and uploading files for a dataset by clicking the *My Datasets* menu link.

Metadata entry, file uploading and landing page preview should be functional.

We have enabled submission to a SWORD-enabled Merritt repository, but have only implemented relevant parts of the SWORD specification and not every functionality in the specification has been implemented.

## Next steps in configuration

### Repository and identifier service configuration

The Stash platform requires an implementation of the [Stash::Repo](https://github.com/CDL-Dryad/stash/tree/main/lib/stash/repo)
API for identifier assignment and submission to repositories.

Dryad uses CDL's EZID service for identifier assignment and stores datasets in the [Merritt](https://merritt.cdlib.org/) repository.
The Stash::Repo implementation is provided by the [stash-merritt](https://github.com/CDLUC3/stash-merritt) gem, which is included in the application [Gemfile](../../Gemfile)
and declared by the `repository:` key in [`app_config.yml`](https://github.com/CDL-Drayd/dryad-config-example/blob/development/config/app_config.yml).
EZID and Merritt/SWORD must be configured for each tenant in the appropriate `tenants/*.yml` file, e.g.

```yaml
repository: # change me: you'll probably have to change all the following indented values and only if using Merritt repo
    type: merritt
    domain: http://merritt-repo-dev-example.cdlib.org
    endpoint: "http://uc3-mrtsword-dev.cdlib.org:39001/mrtsword/collection/my_collection_id"
    username: "submitter_username"
    password: "submitter_password"
 identifier_service: # change me: the identifier service is EZID here, may need to change this
    shoulder: "doi:10.5072/FK2"
    account: my_account_name
    password: my_account_password
    id_scheme: doi
    owner: null
```
