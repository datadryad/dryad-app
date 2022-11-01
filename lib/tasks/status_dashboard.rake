# frozen_string_literal: true

namespace :status_dashboard do

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

    BASELINE_EXTERNAL_DEPENDENCIES.each do |dependency_hash|
      StashEngine::ExternalDependency.create(dependency_hash)
    end
  end

  # rubocop:disable Layout/LineLength
  BASELINE_EXTERNAL_DEPENDENCIES = [
    {
      abbreviation: 'solr',
      name: 'Solr',
      description: 'The Solr engine that drives the Dryad "Explore Data" pages',
      documentation: 'Solr drives the logic behind the \'Explore Data\' section of the application. <br /><br />If the log is reporting a connection error then it is likely that Solr is not running. You will need to log onto the Solr instance and restart it: <blockquote>/dryad/apps/init.d/solr.dryad start</blockquote><br />For information on how to manage Dryad\'s instance of Solr/Geoblacklight please see: <a href="https://confluence.ucop.edu/display/UC3/Dash-Stash+Solr" target="_blank">https://confluence.ucop.edu/display/UC3/Dash-Stash+Solr</a>',
      internally_managed: true,
      status: 1
    },
    {
      abbreviation: 'notifier',
      name: 'Stash Notifier',
      description: 'The service that lets Dryad know when Merritt has finished processing (via the OAI-PMH feed)',
      documentation: 'If the OAI-PMH feed is working and the item is present, check the stash-notifier logs.  A pid file that was never removed may prevent the notifier from processing additional items since it believes a notifier instance is already running.  You may need to remove the pid file or look to see if there is some problem with the notifier.  Maybe a server got shut down in the middle of a run so the notifier didn\'t have a chance to remove it\'s own pid.',
      internally_managed: true,
      status: 1
    },
    {
      abbreviation: 'db_backup',
      name: 'Database Backups',
      description: 'The service manages short-term backups of the database',
      documentation: 'This is managed by the 30-minute cron job on the server.',
      internally_managed: true,
      status: 1
    },
    {
      abbreviation: 'submission_queue',
      name: 'Submission Queue',
      description: 'The submission queue manages processing of submissions to Merritt',
      documentation: '',
      internally_managed: true,
      status: 1
    },
    {
      abbreviation: 'oai',
      name: 'Merritt OAI server',
      description: 'The Merritt OAI server that Dryad uses to determine the status of a dataset submission',
      documentation: 'The OAI-PMH feed is how Dryad determines the state of a Merritt submission after the user submits their dataset.<br><br>For further information on OAI-PMH, please refer to the <a href="https://confluence.ucop.edu/display/Stash/Dryad+Operations#DryadOperations-TestingtheOAI-PMHfeedwegetfromMerritt" target="_blank">Testing OAI-PMH feed</a> document on confluence.',
      internally_managed: true,
      status: 1
    },
    {
      abbreviation: 'download',
      name: 'Merritt Download server',
      description: 'The Merritt server used to retrieve/download dataset files',
      documentation: 'The Merritt download service is used to download a dataset\'s files. It is found on the dataset landing page and involves the `stash_engine/lib/stash/download` and the `stash_engine/lib/repo` files.',
      internally_managed: true,
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
      abbreviation: 'event_data',
      name: 'Datacite Event Data',
      description: 'Dryad uses Datacite\'s EventData API to gather Counter statistics',
      documentation: 'Dryad uses the EventData API to collect statistics for Counter.<br><br>The logic behind this integration can be found in `stash_engine/lib/stash/event_data`',
      internally_managed: false,
      status: 1
    },
    {
      abbreviation: 'event_data_citation',
      name: 'DataCite Event Data Citations Pre-population',
      description: 'Checks logs for new or updated citations checker from event data. Checks the script ran successfully',
      documentation: 'It checks the log for the rake task "counter:populate_citations" from the weekly cron.' \
                     'The cron logs to /apps/dryad/apps/ui/shared/cron/logs/citation_populator.log.' \
                     'Looks for "Completed populating citations" and date that is not too old.',
      internally_managed: true,
      status: 1
    },
    {
      abbreviation: 'counter_calculation',
      name: 'Counter Calculation Script',
      description: 'Dryad calculates stats weekly and submits them to the DataCite hub, required for correct stats',
      documentation: 'Dryad calculates the stats using a Python library that may run for a few days. https://github.com/CDLUC3/counter-processor .  It should submit stats after running and by done by late in the week (Thursday).  It checks the log to see if it ran.',
      internally_managed: true,
      status: 1
    }
  ].freeze
  # rubocop:enable Layout/LineLength
end
