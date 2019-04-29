# see for setting up factorybot https://medium.com/@lukepierotti/setting-up-rspec-and-factory-bot-3bb2153fb909

require 'spec_helper'
require 'time'

FactoryBot.define do
  factory(:user, class: StashEngine::User) do
    first_name { 'Juanita' }
    last_name { 'Collins' }
    email { 'juanita.collins@example.org' }
    tenant_id { 'exemplia' }
    role { 'user' }
    orcid { '1098-415-1212' }
    migration_token { 'xxxxxx' }
    old_dryad_email { 'lolinda@example.com' }
    eperson_id { 37 }
  end

  factory(:identifier, class: StashEngine::Identifier) do
    identifier { '10.1072/FK2something' }
    identifier_type { 'DOI' }
  end

  #  factory(:curation_activity, class: StashEngine::CurationActivity) do
  #    status { 'Unsubmitted' }
  #    note { 'article was not published' }
  #    keywords { 'foo bar' }
  #  end

  factory(:resource, class: StashEngine::Resource) do
    title { 'My test factory' }
    tenant_id { 'dryad' }
    skip_emails { true }
    publication_date { Time.iso8601('2008-09-15T15:53:00z') }
  end

  factory(:version, class: StashEngine::Version) do
    version { 1 }
    merritt_version { 1 }
  end

  factory(:resource_state, class: StashEngine::ResourceState) do
    resource_state { 'submitted' }
  end

  factory(:author, class: StashEngine::Author) do
    author_first_name { 'Gargcelia' }
    author_last_name { 'McVie' }
    author_email { 'gargcelia@mailinator.com' }
    author_orcid { '1111-3333-2222-4444' }
    affiliation { [create(:affiliation)] }
  end

  factory(:affiliation, class: StashDatacite::Affiliation) do
    long_name { 'University of the Pacific' }
  end

  factory(:contributor, class: StashDatacite::Contributor) do
    contributor_name { 'State Key Laboratory for Oxo Synthesis and Selective Oxidation' }
    contributor_type { 'funder' }
    award_number { '12xu' }
  end

  factory(:datacite_date, class: StashDatacite::DataciteDate) do
    date { '2018-11-14T01:04:02Z' }
    date_type { 'available' }
  end

  factory(:description, class: StashDatacite::Description) do
    description { '<p>Cat <sup>below<sub>squared</sub></sup></p>' }
    description_type { 'abstract' }
  end

  factory(:geolocation, class: StashDatacite::Geolocation) do

  end

  factory(:geolocation_box, class: StashDatacite::GeolocationBox) do
    sw_latitude { 34.270836 }
    ne_latitude { 43.612217 }
    sw_longitude { -128.671875 }
    ne_longitude { -95.888672 }
  end

  factory(:geolocation_place, class: StashDatacite::GeolocationPlace) do
    geo_location_place { 'Oakland' }
  end

  factory(:geolocation_point, class: StashDatacite::GeolocationPoint) do
    latitude { 37.00 }
    longitude { -122 }
  end

  factory(:publication_year, class: StashDatacite::PublicationYear) do
    publication_year { 2018 }
  end

  factory(:publisher, class: StashDatacite::Publisher) do
    publisher { 'Dryad' }
  end

  factory(:related_identifier, class: StashDatacite::RelatedIdentifier) do
    related_identifier { 'doi:10.1111/jeb.12260' }
    related_identifier_type { 'doi' }
    relation_type { 'iscitedby' }
  end

  factory(:resource_type, class: StashDatacite::ResourceType) do
    resource_type_general { 'dataset' }
    resource_type { 'dataset' }
  end

  factory(:right, class: StashDatacite::Right) do
    rights { 'CC0 1.0 Universal (CC0 1.0) Public Domain Dedication' }
    rights_uri { 'https://creativecommons.org/publicdomain/zero/1.0/' }
  end

  factory(:subject, class: StashDatacite::Subject) do
    subject { 'freshwater cats' }
    resources { [create(:resource)] }
  end

  factory(:internal_data, class: StashEngine::InternalDatum) do
    data_type { 'publicationName' }
    value { 'Journal of Testing Fun' }
  end
end
