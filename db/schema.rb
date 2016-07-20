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

ActiveRecord::Schema.define(version: 20160720211329) do

  create_table "bookmarks", force: :cascade do |t|
    t.integer  "user_id",       limit: 4,   null: false
    t.string   "user_type",     limit: 255
    t.string   "document_id",   limit: 255
    t.string   "title",         limit: 255
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.string   "document_type", limit: 255
  end

  add_index "bookmarks", ["user_id"], name: "index_bookmarks_on_user_id", using: :btree

  create_table "dcs_affiliations", force: :cascade do |t|
    t.string   "short_name",   limit: 255
    t.string   "long_name",    limit: 255
    t.string   "abbreviation", limit: 255
    t.string   "campus",       limit: 255
    t.string   "logo",         limit: 255
    t.string   "url",          limit: 255
    t.text     "url_text",     limit: 65535
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  create_table "dcs_affiliations_dcs_contributors", force: :cascade do |t|
    t.integer  "affiliation_id", limit: 4
    t.integer  "contributor_id", limit: 4
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "dcs_affiliations_dcs_creators", force: :cascade do |t|
    t.integer  "affiliation_id", limit: 4
    t.integer  "creator_id",     limit: 4
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "dcs_contributors", force: :cascade do |t|
    t.string   "contributor_name",   limit: 255
    t.string   "contributor_type",   limit: 21,  default: "funder"
    t.integer  "name_identifier_id", limit: 4
    t.integer  "resource_id",        limit: 4
    t.datetime "created_at",                                        null: false
    t.datetime "updated_at",                                        null: false
    t.string   "award_number",       limit: 255
  end

  create_table "dcs_creators", force: :cascade do |t|
    t.string   "creator_first_name", limit: 255
    t.string   "creator_last_name",  limit: 255
    t.integer  "name_identifier_id", limit: 4
    t.integer  "resource_id",        limit: 4
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
  end

  create_table "dcs_dates", force: :cascade do |t|
    t.date     "date"
    t.string   "date_type",   limit: 11
    t.integer  "resource_id", limit: 4
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "dcs_descriptions", force: :cascade do |t|
    t.text     "description",      limit: 65535
    t.string   "description_type", limit: 17
    t.integer  "resource_id",      limit: 4
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
  end

  create_table "dcs_embargoes", force: :cascade do |t|
    t.string   "embargo_type", limit: 11,  default: "none"
    t.string   "period",       limit: 255
    t.date     "start_date"
    t.date     "end_date"
    t.integer  "resource_id",  limit: 4
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
  end

  create_table "dcs_geo_location_boxes", force: :cascade do |t|
    t.decimal  "sw_latitude",            precision: 10, scale: 6
    t.decimal  "ne_latitude",            precision: 10, scale: 6
    t.decimal  "sw_longitude",           precision: 10, scale: 6
    t.decimal  "ne_longitude",           precision: 10, scale: 6
    t.integer  "resource_id",  limit: 4
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
  end

  create_table "dcs_geo_location_places", force: :cascade do |t|
    t.string   "geo_location_place", limit: 255
    t.integer  "resource_id",        limit: 4
    t.datetime "created_at",                                              null: false
    t.datetime "updated_at",                                              null: false
    t.decimal  "latitude",                       precision: 10, scale: 6
    t.decimal  "longitude",                      precision: 10, scale: 6
  end

  create_table "dcs_geo_location_points", force: :cascade do |t|
    t.decimal  "latitude",              precision: 10, scale: 6
    t.decimal  "longitude",             precision: 10, scale: 6
    t.integer  "resource_id", limit: 4
    t.datetime "created_at",                                     null: false
    t.datetime "updated_at",                                     null: false
  end

  create_table "dcs_name_identifiers", force: :cascade do |t|
    t.string   "name_identifier",        limit: 255
    t.string   "name_identifier_scheme", limit: 255
    t.text     "scheme_URI",             limit: 65535
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
  end

  create_table "dcs_publication_years", force: :cascade do |t|
    t.string   "publication_year", limit: 255
    t.integer  "resource_id",      limit: 4
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  create_table "dcs_publishers", force: :cascade do |t|
    t.string   "publisher",   limit: 255
    t.integer  "resource_id", limit: 4
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "dcs_related_identifiers", force: :cascade do |t|
    t.string   "related_identifier",      limit: 255
    t.string   "related_identifier_type", limit: 7
    t.string   "relation_type",           limit: 19
    t.text     "related_metadata_scheme", limit: 65535
    t.text     "scheme_URI",              limit: 65535
    t.string   "scheme_type",             limit: 255
    t.integer  "resource_id",             limit: 4
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
  end

  create_table "dcs_resource_types", force: :cascade do |t|
    t.string   "resource_type", limit: 19
    t.integer  "resource_id",   limit: 4
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "dcs_rights", force: :cascade do |t|
    t.string   "rights",      limit: 255
    t.text     "rights_uri",  limit: 65535
    t.integer  "resource_id", limit: 4
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  create_table "dcs_sizes", force: :cascade do |t|
    t.string   "size",        limit: 255
    t.integer  "resource_id", limit: 4
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "dcs_subjects", force: :cascade do |t|
    t.string   "subject",        limit: 255
    t.string   "subject_scheme", limit: 255
    t.text     "scheme_URI",     limit: 65535
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  create_table "dcs_subjects_stash_engine_resources", force: :cascade do |t|
    t.integer  "resource_id", limit: 4
    t.integer  "subject_id",  limit: 4
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  create_table "dcs_titles", force: :cascade do |t|
    t.string   "title",       limit: 255
    t.string   "title_type",  limit: 16
    t.integer  "resource_id", limit: 4
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "dcs_versions", force: :cascade do |t|
    t.string   "version",     limit: 255
    t.integer  "resource_id", limit: 4
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   limit: 4,     default: 0, null: false
    t.integer  "attempts",   limit: 4,     default: 0, null: false
    t.text     "handler",    limit: 65535,             null: false
    t.text     "last_error", limit: 65535
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by",  limit: 255
    t.string   "queue",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "searches", force: :cascade do |t|
    t.text     "query_params", limit: 65535
    t.integer  "user_id",      limit: 4
    t.string   "user_type",    limit: 255
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "searches", ["user_id"], name: "index_searches_on_user_id", using: :btree

  create_table "stash_engine_file_uploads", force: :cascade do |t|
    t.string   "upload_file_name",    limit: 255
    t.string   "upload_content_type", limit: 255
    t.integer  "upload_file_size",    limit: 4
    t.integer  "resource_id",         limit: 4
    t.datetime "upload_updated_at"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.text     "temp_file_path",      limit: 65535
  end

  create_table "stash_engine_identifiers", force: :cascade do |t|
    t.string   "identifier",      limit: 255
    t.string   "identifier_type", limit: 255
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  create_table "stash_engine_image_uploads", force: :cascade do |t|
    t.string   "image_name",       limit: 255
    t.string   "image_type",       limit: 255
    t.integer  "image_size",       limit: 4
    t.integer  "resource_id",      limit: 4
    t.datetime "image_updated_at"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  create_table "stash_engine_resource_states", force: :cascade do |t|
    t.integer  "user_id",        limit: 4
    t.string   "resource_state", limit: 11
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.integer  "resource_id",    limit: 4
  end

  create_table "stash_engine_resource_usages", force: :cascade do |t|
    t.integer "resource_id", limit: 4
    t.integer "downloads",   limit: 4
    t.integer "views",       limit: 4
  end

  create_table "stash_engine_resources", force: :cascade do |t|
    t.integer  "user_id",                   limit: 4
    t.integer  "current_resource_state_id", limit: 4
    t.datetime "created_at",                                            null: false
    t.datetime "updated_at",                                            null: false
    t.boolean  "geolocation",                           default: false
    t.string   "download_uri",              limit: 255
    t.integer  "identifier_id",             limit: 4
    t.string   "update_uri",                limit: 255
  end

  create_table "stash_engine_submission_logs", force: :cascade do |t|
    t.integer  "resource_id",                limit: 4
    t.text     "archive_response",           limit: 65535
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.text     "archive_submission_request", limit: 65535
  end

  create_table "stash_engine_users", force: :cascade do |t|
    t.string   "first_name",  limit: 255
    t.string   "last_name",   limit: 255
    t.string   "email",       limit: 255
    t.string   "uid",         limit: 255
    t.string   "provider",    limit: 255
    t.string   "oauth_token", limit: 255
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
    t.string   "tenant_id",   limit: 255
    t.boolean  "orcid",                   default: false
  end

  add_index "stash_engine_users", ["tenant_id"], name: "index_stash_engine_users_on_tenant_id", using: :btree

  create_table "stash_engine_versions", force: :cascade do |t|
    t.integer  "version",      limit: 4
    t.string   "zip_filename", limit: 255
    t.integer  "resource_id",  limit: 4
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  limit: 255, default: "",    null: false
    t.string   "encrypted_password",     limit: 255, default: "",    null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          limit: 4,   default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
    t.boolean  "guest",                              default: false
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
