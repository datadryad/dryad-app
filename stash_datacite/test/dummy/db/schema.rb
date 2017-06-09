# encoding: UTF-8

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20_151_116_143_020) do

  create_table 'dcs_affliations', force: :cascade do |t|
    t.string   'short_name',   limit: 255
    t.string   'long_name',    limit: 255
    t.string   'abbreviation', limit: 255
    t.string   'campus',       limit: 255
    t.string   'logo',         limit: 255
    t.string   'url',          limit: 255
    t.text     'url_text',     limit: 65_535
    t.datetime 'created_at',                 null: false
    t.datetime 'updated_at',                 null: false
  end

  create_table 'dcs_contributors', force: :cascade do |t|
    t.string   'contributor_name',   limit: 255
    t.string   'contributor_type',   limit: 6, default: 'funder'
    t.integer  'name_identifier_id', limit: 4
    t.integer  'affliation_id',      limit: 4
    t.integer  'resource_id',        limit: 4
    t.datetime 'created_at',                                        null: false
    t.datetime 'updated_at',                                        null: false
  end

  create_table 'dcs_creators', force: :cascade do |t|
    t.string   'creator_first_name', limit: 255
    t.string   'creator_last_name',  limit: 255
    t.integer  'name_identifier_id', limit: 4
    t.integer  'affliation_id',      limit: 4
    t.integer  'resource_id',        limit: 4
    t.datetime 'created_at',                     null: false
    t.datetime 'updated_at',                     null: false
  end

  create_table 'dcs_dates', force: :cascade do |t|
    t.date     'date'
    t.string   'date_type',   limit: 11
    t.integer  'resource_id', limit: 4
    t.datetime 'created_at',             null: false
    t.datetime 'updated_at',             null: false
  end

  create_table 'dcs_descriptions', force: :cascade do |t|
    t.text     'description',      limit: 65_535
    t.string   'description_type', limit: 11
    t.integer  'resource_id',      limit: 4
    t.datetime 'created_at',                     null: false
    t.datetime 'updated_at',                     null: false
  end

  create_table 'dcs_embargoes', force: :cascade do |t|
    t.string   'embargo_type', limit: 11, default: 'none'
    t.string   'period',       limit: 255
    t.date     'start_date'
    t.date     'end_date'
    t.integer  'resource_id', limit: 4
    t.datetime 'created_at',                                null: false
    t.datetime 'updated_at',                                null: false
  end

  create_table 'dcs_geo_location_boxes', force: :cascade do |t|
    t.float    'sw_latitude',  limit: 24
    t.float    'ne_latitude',  limit: 24
    t.float    'sw_longitude', limit: 24
    t.float    'ne_longitude', limit: 24
    t.integer  'resource_id',  limit: 4
    t.datetime 'created_at',              null: false
    t.datetime 'updated_at',              null: false
  end

  create_table 'dcs_geo_location_places', force: :cascade do |t|
    t.string   'geo_location_place', limit: 255
    t.integer  'resource_id',        limit: 4
    t.datetime 'created_at',                     null: false
    t.datetime 'updated_at',                     null: false
  end

  create_table 'dcs_geo_location_points', force: :cascade do |t|
    t.float    'latitude',    limit: 24
    t.float    'longitude',   limit: 24
    t.integer  'resource_id', limit: 4
    t.datetime 'created_at',             null: false
    t.datetime 'updated_at',             null: false
  end

  create_table 'dcs_name_identifiers', force: :cascade do |t|
    t.string   'name_identifier',        limit: 255
    t.string   'name_identifier_scheme', limit: 255
    t.text     'scheme_URI',             limit: 65_535
    t.datetime 'created_at',                           null: false
    t.datetime 'updated_at',                           null: false
  end

  create_table 'dcs_publication_years', force: :cascade do |t|
    t.string   'publication_year', limit: 255
    t.integer  'resource_id',      limit: 4
    t.datetime 'created_at',                   null: false
    t.datetime 'updated_at',                   null: false
  end

  create_table 'dcs_publishers', force: :cascade do |t|
    t.string   'publisher',   limit: 255
    t.integer  'resource_id', limit: 4
    t.datetime 'created_at',              null: false
    t.datetime 'updated_at',              null: false
  end

  create_table 'dcs_related_identifier_types', force: :cascade do |t|
    t.string   'related_identifier_type', limit: 255
    t.datetime 'created_at',                          null: false
    t.datetime 'updated_at',                          null: false
  end

  create_table 'dcs_related_identifiers', force: :cascade do |t|
    t.string   'related_identifier',         limit: 255
    t.integer  'related_identifier_type_id', limit: 4
    t.integer  'relation_type_id',           limit: 4
    t.integer  'resource_id',                limit: 4
    t.datetime 'created_at',                             null: false
    t.datetime 'updated_at',                             null: false
  end

  create_table 'dcs_relation_types', force: :cascade do |t|
    t.string   'relation_type',           limit: 255
    t.string   'related_metadata_scheme', limit: 255
    t.text     'scheme_URI',              limit: 65_535
    t.string   'scheme_type',             limit: 255
    t.datetime 'created_at',                            null: false
    t.datetime 'updated_at',                            null: false
  end

  create_table 'dcs_resource_types', force: :cascade do |t|
    t.string   'resource_type', limit: 20
    t.integer  'resource_id',   limit: 4
    t.datetime 'created_at',               null: false
    t.datetime 'updated_at',               null: false
  end

  create_table 'dcs_rights', force: :cascade do |t|
    t.string   'rights',      limit: 255
    t.text     'rights_URI',  limit: 65_535
    t.integer  'resource_id', limit: 4
    t.datetime 'created_at',                null: false
    t.datetime 'updated_at',                null: false
  end

  create_table 'dcs_sizes', force: :cascade do |t|
    t.string   'size',        limit: 255
    t.integer  'resource_id', limit: 4
    t.datetime 'created_at',              null: false
    t.datetime 'updated_at',              null: false
  end

  create_table 'dcs_subjects', force: :cascade do |t|
    t.string   'subject',        limit: 255
    t.string   'subject_scheme', limit: 255
    t.text     'scheme_URI',     limit: 65_535
    t.integer  'resource_id',    limit: 4
    t.datetime 'created_at',                   null: false
    t.datetime 'updated_at',                   null: false
  end

  create_table 'dcs_titles', force: :cascade do |t|
    t.string   'title',       limit: 255
    t.string   'title_type',  limit: 17, default: 'main'
    t.integer  'resource_id', limit: 4
    t.datetime 'created_at',                               null: false
    t.datetime 'updated_at',                               null: false
  end

  create_table 'dcs_versions', force: :cascade do |t|
    t.string   'version',     limit: 255
    t.integer  'resource_id', limit: 4
    t.datetime 'created_at',              null: false
    t.datetime 'updated_at',              null: false
  end

end
