# :nocov:
require 'json'
# frozen_string_literal: true
# rubocop:disable Metrics/BlockLength
namespace :tenants do

  start_tenants = [
    {
      id: 'dryad',
      short_name: 'Dryad',
      long_name: 'Dryad Data Platform',
      authentication: { strategy: nil }.to_json,
      campus_contacts: Rails.env.include?('production') ? [].to_json : ['devs@datadryad.org'].to_json,
      payment_plan: nil,
      enabled: true,
      partner_display: false,
      covers_dpc: false,
      sponsor_id: nil,
      ror_orgs: ['https://ror.org/00x6h5n95']
    },
    {
      id: 'dryad_ip',
      short_name: 'Dryad IP Address Test',
      long_name: 'Dryad Data Platform IP Address Test',
      authentication: { strategy: 'ip_address', ranges: ['128.48.67.15/255.255.255.0', '127.0.0.1/255.255.255.0'] }.to_json,
      campus_contacts: Rails.env.include?('production') ? [].to_json : ['devs@datadryad.org'].to_json,
      payment_plan: nil,
      enabled: !Rails.env.include?('production'),
      partner_display: false,
      covers_dpc: false,
      sponsor_id: nil,
      ror_orgs: nil
    }
  ].freeze

  desc 'Seed the tenants table'
  task seed: :environment do
    p 'Seeding the tenants table.'
    start_tenants.each do |tenant_hash|
      StashEngine::Tenant.find_or_create_by(tenant_hash.except(:ror_orgs))
    end

    p 'Seeding the tenant_ror_orgs table'
    start_tenants.each do |tenant|
      tenant[:ror_orgs]&.each do |ror_id|
        StashEngine::TenantRorOrg.find_or_create_by(tenant_id: tenant[:id], ror_id: ror_id)
      end
    end
  end

  desc 'Rename bad tenants'
  task :rename, [:dir] => :environment do |_task, args|
    if ApplicationRecord.connection.foreign_key_exists?(:stash_engine_tenant_ror_orgs, :stash_engine_tenants)
      ApplicationRecord.connection.remove_foreign_key :stash_engine_tenant_ror_orgs, :stash_engine_tenants, column: :tenant_id
    end
    if args.dir == 'reverse'
      p 'Reversing tenant id changes.'

      StashEngine::Tenant.find('shef').update(id: 'sheffield')
      StashEngine::TenantRorOrg.where(tenant_id: 'shef').update_all(tenant_id: 'sheffield')
      StashEngine::User.where(tenant_id: 'shef').update_all(tenant_id: 'sheffield')
      StashEngine::Resource.where(tenant_id: 'shef').update_all(tenant_id: 'sheffield')
      StashEngine::Identifier.where(payment_id: 'shef').update_all(payment_id: 'sheffield')
      StashEngine::Tenant.find('lbl').update(id: 'lbnl')
      StashEngine::TenantRorOrg.where(tenant_id: 'lbl').update_all(tenant_id: 'lbnl')
      StashEngine::User.where(tenant_id: 'lbl').update_all(tenant_id: 'lbnl')
      StashEngine::Resource.where(tenant_id: 'lbl').update_all(tenant_id: 'lbnl')
      StashEngine::Identifier.where(payment_id: 'lbl').update_all(payment_id: 'lbnl')
      StashEngine::Tenant.find('csueastbay').update(id: 'csueb')
      StashEngine::TenantRorOrg.where(tenant_id: 'csueastbay').update_all(tenant_id: 'csueb')
      StashEngine::User.where(tenant_id: 'csueastbay').update_all(tenant_id: 'csueb')
      StashEngine::Resource.where(tenant_id: 'csueastbay').update_all(tenant_id: 'csueb')
      StashEngine::Identifier.where(payment_id: 'csueastbay').update_all(payment_id: 'csueb')
      StashEngine::Tenant.find('vu').update(id: 'victoria')
      StashEngine::TenantRorOrg.where(tenant_id: 'vu').update_all(tenant_id: 'victoria')
      StashEngine::User.where(tenant_id: 'vu').update_all(tenant_id: 'victoria')
      StashEngine::Resource.where(tenant_id: 'vu').update_all(tenant_id: 'victoria')
      StashEngine::Identifier.where(payment_id: 'vu').update_all(payment_id: 'victoria')
      StashEngine::Tenant.find('unsw').update(id: 'sydneynsw')
      StashEngine::TenantRorOrg.where(tenant_id: 'unsw').update_all(tenant_id: 'sydneynsw')
      StashEngine::User.where(tenant_id: 'unsw').update_all(tenant_id: 'sydneynsw')
      StashEngine::Resource.where(tenant_id: 'unsw').update_all(tenant_id: 'sydneynsw')
      StashEngine::Identifier.where(payment_id: 'unsw').update_all(payment_id: 'sydneynsw')
      StashEngine::Tenant.find('osu').update(id: 'ohiostate')
      StashEngine::TenantRorOrg.where(tenant_id: 'osu').update_all(tenant_id: 'ohiostate')
      StashEngine::User.where(tenant_id: 'osu').update_all(tenant_id: 'ohiostate')
      StashEngine::Resource.where(tenant_id: 'osu').update_all(tenant_id: 'ohiostate')
      StashEngine::Identifier.where(payment_id: 'osu').update_all(payment_id: 'ohiostate')
      StashEngine::Tenant.find('msu').update(id: 'msu2')
      StashEngine::TenantRorOrg.where(tenant_id: 'msu').update_all(tenant_id: 'msu2')
      StashEngine::User.where(tenant_id: 'msu').update_all(tenant_id: 'msu2')
      StashEngine::Resource.where(tenant_id: 'msu').update_all(tenant_id: 'msu2')
      StashEngine::Identifier.where(payment_id: 'msu').update_all(payment_id: 'msu2')
      StashEngine::Tenant.find('montana').update(id: 'msu')
      StashEngine::TenantRorOrg.where(tenant_id: 'montana').update_all(tenant_id: 'msu')
      StashEngine::User.where(tenant_id: 'montana').update_all(tenant_id: 'msu')
      StashEngine::Resource.where(tenant_id: 'montana').update_all(tenant_id: 'msu')
      StashEngine::Identifier.where(payment_id: 'montana').update_all(payment_id: 'msu')

      # UC system
      StashEngine::Tenant.find('berkeley').update(id: 'ucb')
      StashEngine::TenantRorOrg.where(tenant_id: 'berkeley').update_all(tenant_id: 'ucb')
      StashEngine::User.where(tenant_id: 'berkeley').update_all(tenant_id: 'ucb')
      StashEngine::Resource.where(tenant_id: 'berkeley').update_all(tenant_id: 'ucb')
      StashEngine::Identifier.where(payment_id: 'berkeley').update_all(payment_id: 'ucb')
      StashEngine::Tenant.find('ucdavis').update(id: 'ucd')
      StashEngine::TenantRorOrg.where(tenant_id: 'ucdavis').update_all(tenant_id: 'ucd')
      StashEngine::User.where(tenant_id: 'ucdavis').update_all(tenant_id: 'ucd')
      StashEngine::Resource.where(tenant_id: 'ucdavis').update_all(tenant_id: 'ucd')
      StashEngine::Identifier.where(payment_id: 'ucdavis').update_all(payment_id: 'ucd')
      StashEngine::Tenant.find('ucmerced').update(id: 'ucm')
      StashEngine::TenantRorOrg.where(tenant_id: 'ucmerced').update_all(tenant_id: 'ucm')
      StashEngine::User.where(tenant_id: 'ucmerced').update_all(tenant_id: 'ucm')
      StashEngine::Resource.where(tenant_id: 'ucmerced').update_all(tenant_id: 'ucm')
      StashEngine::Identifier.where(payment_id: 'ucmerced').update_all(payment_id: 'ucm')

      # SUNY consortium
      StashEngine::Tenant.find('buffalo').update(id: 'suny-buffalo')
      StashEngine::TenantRorOrg.where(tenant_id: 'buffalo').update_all(tenant_id: 'suny-buffalo')
      StashEngine::User.where(tenant_id: 'buffalo').update_all(tenant_id: 'suny-buffalo')
      StashEngine::Resource.where(tenant_id: 'buffalo').update_all(tenant_id: 'suny-buffalo')
      StashEngine::Identifier.where(payment_id: 'buffalo').update_all(payment_id: 'suny-buffalo')
      StashEngine::Tenant.find('buffalostate').update(id: 'suny-buffalostate')
      StashEngine::TenantRorOrg.where(tenant_id: 'buffalostate').update_all(tenant_id: 'suny-buffalostate')
      StashEngine::User.where(tenant_id: 'buffalostate').update_all(tenant_id: 'suny-buffalostate')
      StashEngine::Resource.where(tenant_id: 'buffalostate').update_all(tenant_id: 'suny-buffalostate')
      StashEngine::Identifier.where(payment_id: 'buffalostate').update_all(payment_id: 'suny-buffalostate')
      StashEngine::Tenant.find('downstate').update(id: 'suny-downstate')
      StashEngine::TenantRorOrg.where(tenant_id: 'downstate').update_all(tenant_id: 'suny-downstate')
      StashEngine::User.where(tenant_id: 'downstate').update_all(tenant_id: 'suny-downstate')
      StashEngine::Resource.where(tenant_id: 'downstate').update_all(tenant_id: 'suny-downstate')
      StashEngine::Identifier.where(payment_id: 'downstate').update_all(payment_id: 'suny-downstate')
      StashEngine::Tenant.find('fredonia').update(id: 'suny-fredonia')
      StashEngine::TenantRorOrg.where(tenant_id: 'fredonia').update_all(tenant_id: 'suny-fredonia')
      StashEngine::User.where(tenant_id: 'fredonia').update_all(tenant_id: 'suny-fredonia')
      StashEngine::Resource.where(tenant_id: 'fredonia').update_all(tenant_id: 'suny-fredonia')
      StashEngine::Identifier.where(payment_id: 'fredonia').update_all(payment_id: 'suny-fredonia')
      StashEngine::Tenant.find('geneseo').update(id: 'suny-geneseo')
      StashEngine::TenantRorOrg.where(tenant_id: 'geneseo').update_all(tenant_id: 'suny-geneseo')
      StashEngine::User.where(tenant_id: 'geneseo').update_all(tenant_id: 'suny-geneseo')
      StashEngine::Resource.where(tenant_id: 'geneseo').update_all(tenant_id: 'suny-geneseo')
      StashEngine::Identifier.where(payment_id: 'geneseo').update_all(payment_id: 'suny-geneseo')
      StashEngine::Tenant.find('stonybrook').update(id: 'suny-stonybrook')
      StashEngine::TenantRorOrg.where(tenant_id: 'stonybrook').update_all(tenant_id: 'suny-stonybrook')
      StashEngine::User.where(tenant_id: 'stonybrook').update_all(tenant_id: 'suny-stonybrook')
      StashEngine::Resource.where(tenant_id: 'stonybrook').update_all(tenant_id: 'suny-stonybrook')
      StashEngine::Identifier.where(payment_id: 'stonybrook').update_all(payment_id: 'suny-stonybrook')

      # Clare consortium
      StashEngine::Tenant.find('claremont').update(id: 'clare-cs')
      StashEngine::Tenant.where(sponsor_id: 'claremont').update_all(sponsor_id: 'clare-cs')
      StashEngine::TenantRorOrg.where(tenant_id: 'claremont').update_all(tenant_id: 'clare-cs')
      StashEngine::User.where(tenant_id: 'claremont').update_all(tenant_id: 'clare-cs')
      StashEngine::Resource.where(tenant_id: 'claremont').update_all(tenant_id: 'clare-cs')
      StashEngine::Identifier.where(payment_id: 'claremont').update_all(payment_id: 'clare-cs')
      StashEngine::Tenant.find('cgu').update(id: 'clare-cgu')
      StashEngine::TenantRorOrg.where(tenant_id: 'cgu').update_all(tenant_id: 'clare-cgu')
      StashEngine::User.where(tenant_id: 'cgu').update_all(tenant_id: 'clare-cgu')
      StashEngine::Resource.where(tenant_id: 'cgu').update_all(tenant_id: 'clare-cgu')
      StashEngine::Identifier.where(payment_id: 'cgu').update_all(payment_id: 'clare-cgu')
      StashEngine::Tenant.find('cmc').update(id: 'clare-cmc')
      StashEngine::TenantRorOrg.where(tenant_id: 'cmc').update_all(tenant_id: 'clare-cmc')
      StashEngine::User.where(tenant_id: 'cmc').update_all(tenant_id: 'clare-cmc')
      StashEngine::Resource.where(tenant_id: 'cmc').update_all(tenant_id: 'clare-cmc')
      StashEngine::Identifier.where(payment_id: 'cmc').update_all(payment_id: 'clare-cmc')
      StashEngine::Tenant.find('hmc').update(id: 'clare-hmc')
      StashEngine::TenantRorOrg.where(tenant_id: 'hmc').update_all(tenant_id: 'clare-hmc')
      StashEngine::User.where(tenant_id: 'hmc').update_all(tenant_id: 'clare-hmc')
      StashEngine::Resource.where(tenant_id: 'hmc').update_all(tenant_id: 'clare-hmc')
      StashEngine::Identifier.where(payment_id: 'hmc').update_all(payment_id: 'clare-hmc')
      StashEngine::Tenant.find('kgi').update(id: 'clare-kgi')
      StashEngine::TenantRorOrg.where(tenant_id: 'kgi').update_all(tenant_id: 'clare-kgi')
      StashEngine::User.where(tenant_id: 'kgi').update_all(tenant_id: 'clare-kgi')
      StashEngine::Resource.where(tenant_id: 'kgi').update_all(tenant_id: 'clare-kgi')
      StashEngine::Identifier.where(payment_id: 'kgi').update_all(payment_id: 'clare-kgi')
      StashEngine::Tenant.find('pitzer').update(id: 'clare-pitzer')
      StashEngine::TenantRorOrg.where(tenant_id: 'pitzer').update_all(tenant_id: 'clare-pitzer')
      StashEngine::User.where(tenant_id: 'pitzer').update_all(tenant_id: 'clare-pitzer')
      StashEngine::Resource.where(tenant_id: 'pitzer').update_all(tenant_id: 'clare-pitzer')
      StashEngine::Identifier.where(payment_id: 'pitzer').update_all(payment_id: 'clare-pitzer')
      StashEngine::Tenant.find('pomona').update(id: 'clare-pomona')
      StashEngine::TenantRorOrg.where(tenant_id: 'pomona').update_all(tenant_id: 'clare-pomona')
      StashEngine::User.where(tenant_id: 'pomona').update_all(tenant_id: 'clare-pomona')
      StashEngine::Resource.where(tenant_id: 'pomona').update_all(tenant_id: 'clare-pomona')
      StashEngine::Identifier.where(payment_id: 'pomona').update_all(payment_id: 'clare-pomona')
      StashEngine::Tenant.find('scrippscollege').update(id: 'clare-scripps')
      StashEngine::TenantRorOrg.where(tenant_id: 'scrippscollege').update_all(tenant_id: 'clare-scripps')
      StashEngine::User.where(tenant_id: 'scrippscollege').update_all(tenant_id: 'clare-scripps')
      StashEngine::Resource.where(tenant_id: 'scrippscollege').update_all(tenant_id: 'clare-scripps')
      StashEngine::Identifier.where(payment_id: 'scrippscollege').update_all(payment_id: 'clare-scripps')
    else
      p 'Correcting tenant ids.'

      StashEngine::Tenant.find('victoria').update(id: 'vu')
      StashEngine::TenantRorOrg.where(tenant_id: 'victoria').update_all(tenant_id: 'vu')
      StashEngine::User.where(tenant_id: 'victoria').update_all(tenant_id: 'vu')
      StashEngine::Resource.where(tenant_id: 'victoria').update_all(tenant_id: 'vu')
      StashEngine::Identifier.where(payment_id: 'victoria').update_all(payment_id: 'vu')
      StashEngine::Tenant.find('msu').update(id: 'montana')
      StashEngine::TenantRorOrg.where(tenant_id: 'msu').update_all(tenant_id: 'montana')
      StashEngine::User.where(tenant_id: 'msu').update_all(tenant_id: 'montana')
      StashEngine::Resource.where(tenant_id: 'msu').update_all(tenant_id: 'montana')
      StashEngine::Identifier.where(payment_id: 'msu').update_all(payment_id: 'montana')
      StashEngine::Tenant.find('msu2').update(id: 'msu')
      StashEngine::TenantRorOrg.where(tenant_id: 'msu2').update_all(tenant_id: 'msu')
      StashEngine::User.where(tenant_id: 'msu2').update_all(tenant_id: 'msu')
      StashEngine::Resource.where(tenant_id: 'msu2').update_all(tenant_id: 'msu')
      StashEngine::Identifier.where(payment_id: 'msu2').update_all(payment_id: 'msu')
      StashEngine::Tenant.find('ohiostate').update(id: 'osu')
      StashEngine::TenantRorOrg.where(tenant_id: 'ohiostate').update_all(tenant_id: 'osu')
      StashEngine::User.where(tenant_id: 'ohiostate').update_all(tenant_id: 'osu')
      StashEngine::Resource.where(tenant_id: 'ohiostate').update_all(tenant_id: 'osu')
      StashEngine::Identifier.where(payment_id: 'ohiostate').update_all(payment_id: 'osu')
      StashEngine::Tenant.find('sydneynsw').update(id: 'unsw')
      StashEngine::TenantRorOrg.where(tenant_id: 'sydneynsw').update_all(tenant_id: 'unsw')
      StashEngine::User.where(tenant_id: 'sydneynsw').update_all(tenant_id: 'unsw')
      StashEngine::Resource.where(tenant_id: 'sydneynsw').update_all(tenant_id: 'unsw')
      StashEngine::Identifier.where(payment_id: 'sydneynsw').update_all(payment_id: 'unsw')
      StashEngine::Tenant.find('csueb').update(id: 'csueastbay')
      StashEngine::TenantRorOrg.where(tenant_id: 'csueb').update_all(tenant_id: 'csueastbay')
      StashEngine::User.where(tenant_id: 'csueb').update_all(tenant_id: 'csueastbay')
      StashEngine::Resource.where(tenant_id: 'csueb').update_all(tenant_id: 'csueastbay')
      StashEngine::Identifier.where(payment_id: 'csueb').update_all(payment_id: 'csueastbay')
      StashEngine::Tenant.find('lbnl').update(id: 'lbl')
      StashEngine::TenantRorOrg.where(tenant_id: 'lbnl').update_all(tenant_id: 'lbl')
      StashEngine::User.where(tenant_id: 'lbnl').update_all(tenant_id: 'lbl')
      StashEngine::Resource.where(tenant_id: 'lbnl').update_all(tenant_id: 'lbl')
      StashEngine::Identifier.where(payment_id: 'lbnl').update_all(payment_id: 'lbl')
      StashEngine::Tenant.find('sheffield').update(id: 'shef')
      StashEngine::TenantRorOrg.where(tenant_id: 'sheffield').update_all(tenant_id: 'shef')
      StashEngine::User.where(tenant_id: 'sheffield').update_all(tenant_id: 'shef')
      StashEngine::Resource.where(tenant_id: 'sheffield').update_all(tenant_id: 'shef')
      StashEngine::Identifier.where(payment_id: 'sheffield').update_all(payment_id: 'shef')

      # Clare consortium
      StashEngine::Tenant.find('clare-cs').update(id: 'claremont')
      StashEngine::Tenant.where(sponsor_id: 'clare-cs').update_all(sponsor_id: 'claremont')
      StashEngine::TenantRorOrg.where(tenant_id: 'clare-cs').update_all(tenant_id: 'claremont')
      StashEngine::User.where(tenant_id: 'clare-cs').update_all(tenant_id: 'claremont')
      StashEngine::Resource.where(tenant_id: 'clare-cs').update_all(tenant_id: 'claremont')
      StashEngine::Identifier.where(payment_id: 'clare-cs').update_all(payment_id: 'claremont')
      StashEngine::Tenant.find('clare-cgu').update(id: 'cgu')
      StashEngine::TenantRorOrg.where(tenant_id: 'clare-cgu').update_all(tenant_id: 'cgu')
      StashEngine::User.where(tenant_id: 'clare-cgu').update_all(tenant_id: 'cgu')
      StashEngine::Resource.where(tenant_id: 'clare-cgu').update_all(tenant_id: 'cgu')
      StashEngine::Identifier.where(payment_id: 'clare-cgu').update_all(payment_id: 'cgu')
      StashEngine::Tenant.find('clare-cmc').update(id: 'cmc')
      StashEngine::TenantRorOrg.where(tenant_id: 'clare-cmc').update_all(tenant_id: 'cmc')
      StashEngine::User.where(tenant_id: 'clare-cmc').update_all(tenant_id: 'cmc')
      StashEngine::Resource.where(tenant_id: 'clare-cmc').update_all(tenant_id: 'cmc')
      StashEngine::Identifier.where(payment_id: 'clare-cmc').update_all(payment_id: 'cmc')
      StashEngine::Tenant.find('clare-hmc').update(id: 'hmc')
      StashEngine::TenantRorOrg.where(tenant_id: 'clare-hmc').update_all(tenant_id: 'hmc')
      StashEngine::User.where(tenant_id: 'clare-hmc').update_all(tenant_id: 'hmc')
      StashEngine::Resource.where(tenant_id: 'clare-hmc').update_all(tenant_id: 'hmc')
      StashEngine::Identifier.where(payment_id: 'clare-hmc').update_all(payment_id: 'hmc')
      StashEngine::Tenant.find('clare-kgi').update(id: 'kgi')
      StashEngine::TenantRorOrg.where(tenant_id: 'clare-kgi').update_all(tenant_id: 'kgi')
      StashEngine::User.where(tenant_id: 'clare-kgi').update_all(tenant_id: 'kgi')
      StashEngine::Resource.where(tenant_id: 'clare-kgi').update_all(tenant_id: 'kgi')
      StashEngine::Identifier.where(payment_id: 'clare-kgi').update_all(payment_id: 'kgi')
      StashEngine::Tenant.find('clare-pitzer').update(id: 'pitzer')
      StashEngine::TenantRorOrg.where(tenant_id: 'clare-pitzer').update_all(tenant_id: 'pitzer')
      StashEngine::User.where(tenant_id: 'clare-pitzer').update_all(tenant_id: 'pitzer')
      StashEngine::Resource.where(tenant_id: 'clare-pitzer').update_all(tenant_id: 'pitzer')
      StashEngine::Identifier.where(payment_id: 'clare-pitzer').update_all(payment_id: 'pitzer')
      StashEngine::Tenant.find('clare-pomona').update(id: 'pomona')
      StashEngine::TenantRorOrg.where(tenant_id: 'clare-pomona').update_all(tenant_id: 'pomona')
      StashEngine::User.where(tenant_id: 'clare-pomona').update_all(tenant_id: 'pomona')
      StashEngine::Resource.where(tenant_id: 'clare-pomona').update_all(tenant_id: 'pomona')
      StashEngine::Identifier.where(payment_id: 'clare-pomona').update_all(payment_id: 'pomona')
      StashEngine::Tenant.find('clare-scripps').update(id: 'scrippscollege')
      StashEngine::TenantRorOrg.where(tenant_id: 'clare-scripps').update_all(tenant_id: 'scrippscollege')
      StashEngine::User.where(tenant_id: 'clare-scripps').update_all(tenant_id: 'scrippscollege')
      StashEngine::Resource.where(tenant_id: 'clare-scripps').update_all(tenant_id: 'scrippscollege')
      StashEngine::Identifier.where(payment_id: 'clare-scripps').update_all(payment_id: 'scrippscollege')

      # SUNY consortium
      StashEngine::Tenant.find('suny-buffalo').update(id: 'buffalo')
      StashEngine::TenantRorOrg.where(tenant_id: 'suny-buffalo').update_all(tenant_id: 'buffalo')
      StashEngine::User.where(tenant_id: 'suny-buffalo').update_all(tenant_id: 'buffalo')
      StashEngine::Resource.where(tenant_id: 'suny-buffalo').update_all(tenant_id: 'buffalo')
      StashEngine::Identifier.where(payment_id: 'suny-buffalo').update_all(payment_id: 'buffalo')
      StashEngine::Tenant.find('suny-buffalostate').update(id: 'buffalostate')
      StashEngine::TenantRorOrg.where(tenant_id: 'suny-buffalostate').update_all(tenant_id: 'buffalostate')
      StashEngine::User.where(tenant_id: 'suny-buffalostate').update_all(tenant_id: 'buffalostate')
      StashEngine::Resource.where(tenant_id: 'suny-buffalostate').update_all(tenant_id: 'buffalostate')
      StashEngine::Identifier.where(payment_id: 'suny-buffalostate').update_all(payment_id: 'buffalostate')
      StashEngine::Tenant.find('suny-downstate').update(id: 'downstate')
      StashEngine::TenantRorOrg.where(tenant_id: 'suny-downstate').update_all(tenant_id: 'downstate')
      StashEngine::User.where(tenant_id: 'suny-downstate').update_all(tenant_id: 'downstate')
      StashEngine::Resource.where(tenant_id: 'suny-downstate').update_all(tenant_id: 'downstate')
      StashEngine::Identifier.where(payment_id: 'suny-downstate').update_all(payment_id: 'downstate')
      StashEngine::Tenant.find('suny-fredonia').update(id: 'fredonia')
      StashEngine::TenantRorOrg.where(tenant_id: 'suny-fredonia').update_all(tenant_id: 'fredonia')
      StashEngine::User.where(tenant_id: 'suny-fredonia').update_all(tenant_id: 'fredonia')
      StashEngine::Resource.where(tenant_id: 'suny-fredonia').update_all(tenant_id: 'fredonia')
      StashEngine::Identifier.where(payment_id: 'suny-fredonia').update_all(payment_id: 'fredonia')
      StashEngine::Tenant.find('suny-geneseo').update(id: 'geneseo')
      StashEngine::TenantRorOrg.where(tenant_id: 'suny-geneseo').update_all(tenant_id: 'geneseo')
      StashEngine::User.where(tenant_id: 'suny-geneseo').update_all(tenant_id: 'geneseo')
      StashEngine::Resource.where(tenant_id: 'suny-geneseo').update_all(tenant_id: 'geneseo')
      StashEngine::Identifier.where(payment_id: 'suny-geneseo').update_all(payment_id: 'geneseo')
      StashEngine::Tenant.find('suny-stonybrook').update(id: 'stonybrook')
      StashEngine::TenantRorOrg.where(tenant_id: 'suny-stonybrook').update_all(tenant_id: 'stonybrook')
      StashEngine::User.where(tenant_id: 'suny-stonybrook').update_all(tenant_id: 'stonybrook')
      StashEngine::Resource.where(tenant_id: 'suny-stonybrook').update_all(tenant_id: 'stonybrook')
      StashEngine::Identifier.where(payment_id: 'suny-stonybrook').update_all(payment_id: 'stonybrook')

      # UC system
      StashEngine::Tenant.find('ucb').update(id: 'berkeley')
      StashEngine::TenantRorOrg.where(tenant_id: 'ucb').update_all(tenant_id: 'berkeley')
      StashEngine::User.where(tenant_id: 'ucb').update_all(tenant_id: 'berkeley')
      StashEngine::Resource.where(tenant_id: 'ucb').update_all(tenant_id: 'berkeley')
      StashEngine::Identifier.where(payment_id: 'ucb').update_all(payment_id: 'berkeley')
      StashEngine::Tenant.find('ucd').update(id: 'ucdavis')
      StashEngine::TenantRorOrg.where(tenant_id: 'ucd').update_all(tenant_id: 'ucdavis')
      StashEngine::User.where(tenant_id: 'ucd').update_all(tenant_id: 'ucdavis')
      StashEngine::Resource.where(tenant_id: 'ucd').update_all(tenant_id: 'ucdavis')
      StashEngine::Identifier.where(payment_id: 'ucd').update_all(payment_id: 'ucdavis')
      StashEngine::Tenant.find('ucm').update(id: 'ucmerced')
      StashEngine::TenantRorOrg.where(tenant_id: 'ucm').update_all(tenant_id: 'ucmerced')
      StashEngine::User.where(tenant_id: 'ucm').update_all(tenant_id: 'ucmerced')
      StashEngine::Resource.where(tenant_id: 'ucm').update_all(tenant_id: 'ucmerced')
      StashEngine::Identifier.where(payment_id: 'ucm').update_all(payment_id: 'ucmerced')
    end
    unless ApplicationRecord.connection.foreign_key_exists?(:stash_engine_tenant_ror_orgs, :stash_engine_tenants)
      ApplicationRecord.connection.add_foreign_key :stash_engine_tenant_ror_orgs, :stash_engine_tenants, column: :tenant_id
    end
  rescue StandardError => e
    p e
    p 'Tenants ids not changed from original'
  end
end
# rubocop:enable Metrics/BlockLength
# :nocov: