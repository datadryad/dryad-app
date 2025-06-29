# frozen_string_literal: true

namespace :status_dashboard do

  # rubocop:disable Layout/LineLength
  baseline_external_dependencies = [
    {
      abbreviation: 'solr',
      name: 'Solr',
      description: 'The Solr engine that drives the Dryad "Explore data" pages',
      documentation: 'Solr drives the logic behind the \'Explore data\' section of the application. <br /><br />If the log is reporting a connection error then it is likely that Solr is not running. You will need to log onto the Solr instance and restart it: <blockquote>/dryad/apps/init.d/solr.dryad start</blockquote><br />For information on how to manage Dryad\'s instance of Solr/Blacklight please see: <a href="https://github.com/datadryad/dryad-app/blob/main/documentation/solr.md" target="_blank">https://github.com/datadryad/dryad-app/blob/main/documentation/solr.md</a>',
      internally_managed: true,
      status: 1
    },
    {
      abbreviation: 'db_backup',
      name: 'Database backups',
      description: 'The service manages short-term backups of the database',
      documentation: 'This is managed by the 30-minute cron job on the server.',
      internally_managed: true,
      status: 1
    },
    {
      abbreviation: 'submission_queue',
      name: 'Submission Queue',
      description: 'The submission queue manages processing of submissions to the repository',
      documentation: '',
      internally_managed: true,
      status: 1
    },
    {
      abbreviation: 'download',
      name: 'AWS S3 downloads',
      description: 'The service used to retrieve/download dataset files',
      documentation: 'The download service is used to download a dataset\'s files. It is found on the dataset landing page and involves the `lib/stash/download` and the `lib/stash/repo` files.',
      internally_managed: false,
      status: 1
    },
    {
      abbreviation: 'datacite',
      name: 'Datacite',
      description: 'The Datacite DOI generation service',
      documentation: 'Dryad uses Datacite to mint DOIs for datasets.<br><br>The logic for this integration lives in `stash_engine/lib/stash/doi`. ',
      internally_managed: false,
      status: 1
    },
    {
      abbreviation: 'stripe',
      name: 'Stripe',
      description: 'Dryad uses Stripe to charge customers when their dataset is embargoed or published',
      documentation: 'Dryad uses Stripe to charge customers when their dataset becomes embargoed or published. We call the Stripe API within the CurationActivity model and then place the Stripe transaction/invoice number on the `stash_engine_identifiers` table.<br /><br />For more information on the outage, refer to the <a href="https://status.stripe.com/" target="_blank">Stripe System Status</a> page.',
      internally_managed: false,
      status: 1
    },
    {
      abbreviation: 'crossref',
      name: 'Crossref',
      description: 'Dryad uses the Crossref API to retrieve additional dataset information',
      documentation: ' Dryad uses the Crossref API to pre-populate a dataset\'s metadata. The logic is triggered on the Dataset entry page when the user enters a publication DOI.<br><br>The core logic behind it can be found in `stash_datacite/app/controllers/publication_controller.rb` and in the `stash_engine/lib/stash/import` directory.',
      internally_managed: false,
      status: 1
    },
    {
      abbreviation: 'orcid',
      name: 'ORCID',
      description: 'Dryad uses ORCID as the primary means for user authentication',
      documentation: 'Dryad uses ORCID as its primary authentication method. If ORCID is down users (including admins) are unable to log into the system.<br/><br/>See the <a href="https://ror.community/" target="_blank">ROR site</a> for further information about the service',
      internally_managed: false,
      status: 1
    },
    {
      abbreviation: 'event_data_citation',
      name: 'DataCite citations population',
      description: 'Checks logs for new or updated citations checker from event data. Checks the script ran successfully',
      documentation: 'It checks the log for the rake task "counter:populate_citations" from the weekly cron.' \
                     'The cron logs to /home/ec2-user/deploy/shared/log/citation_populator.log.' \
                     'Looks for "Completed populating citations" and date that is not too old.',
      internally_managed: true,
      status: 1
    },
    {
      abbreviation: 'wordpress',
      name: 'Wordpress',
      description: 'Hosts the Dryad blog',
      documentation: 'Dryad uses Wordpress to host its blog, and uses the RSS feed generated there to show latest posts on the main Dryad site. ',
      internally_managed: false,
      status: 1
    },
    {
      abbreviation: 'shibboleth',
      name: 'Shibboleth',
      description: 'Shibboleth login',
      documentation: 'Dryad uses Shibboleth to validate that users are affiliated with member institutions. ',
      internally_managed: true,
      status: 1
    }
  ].freeze
  # rubocop:enable Layout/LineLength

  desc 'Check Solr'
  task check: :environment do
    StashEngine::ExternalDependency.all.each do |dependency|
      class_name = "StashEngine::StatusDashboard::#{dependency.abbreviation.titleize.delete(' ')}Service"
      begin
        svc = Object.const_get(class_name).new(abbreviation: dependency.abbreviation)
        online = svc.ping_dependency
        p "#{online ? 'online' : 'OFFLINE'} <== #{dependency.name}"
      rescue NameError => e
        p "Unable to locate a service for #{dependency.name}: #{e.message}"
        dependency.update(status: 2, error_message: "There is no #{class_name} defined! Unable to ping dependency.")
        next
      end
    end
    p 'If any errors were reported, please refer to the `stash_engine_external_dependencies` table for details.'
  end

  desc 'Seed the external_dependencies table'
  task seed: :environment do
    p 'Seeding the external_dependencies table.'
    StashEngine::ExternalDependency.all.destroy_all

    baseline_external_dependencies.each do |dependency_hash|
      StashEngine::ExternalDependency.create(dependency_hash)
    end
  end
end
