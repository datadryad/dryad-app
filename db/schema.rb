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

ActiveRecord::Schema.define(version: 20180316234058) do

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
    t.text     "short_name",   limit: 65535
    t.text     "long_name",    limit: 65535
    t.text     "abbreviation", limit: 65535
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "dcs_affiliations", ["long_name"], name: "index_dcs_affiliations_on_long_name", length: {"long_name"=>50}, using: :btree
  add_index "dcs_affiliations", ["short_name"], name: "index_dcs_affiliations_on_short_name", length: {"short_name"=>50}, using: :btree

  create_table "dcs_affiliations_authors", force: :cascade do |t|
    t.integer  "affiliation_id", limit: 4
    t.integer  "author_id",      limit: 4
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "dcs_affiliations_authors", ["affiliation_id"], name: "index_dcs_affiliations_authors_on_affiliation_id", using: :btree
  add_index "dcs_affiliations_authors", ["author_id"], name: "index_dcs_affiliations_authors_on_author_id", using: :btree

  create_table "dcs_affiliations_contributors", force: :cascade do |t|
    t.integer  "affiliation_id", limit: 4
    t.integer  "contributor_id", limit: 4
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "dcs_affiliations_contributors", ["affiliation_id"], name: "index_dcs_affiliations_contributors_on_affiliation_id", using: :btree
  add_index "dcs_affiliations_contributors", ["contributor_id"], name: "index_dcs_affiliations_contributors_on_contributor_id", using: :btree

  create_table "dcs_alternate_identifiers", force: :cascade do |t|
    t.text     "alternate_identifier",      limit: 65535
    t.text     "alternate_identifier_type", limit: 65535
    t.integer  "resource_id",               limit: 4,     null: false
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
  end

  add_index "dcs_alternate_identifiers", ["resource_id"], name: "index_dcs_alternate_identifiers_on_resource_id", using: :btree

  create_table "dcs_contributors", force: :cascade do |t|
    t.text     "contributor_name",   limit: 65535
    t.string   "contributor_type",   limit: 21,    default: "funder"
    t.integer  "name_identifier_id", limit: 4
    t.integer  "resource_id",        limit: 4
    t.datetime "created_at",                                          null: false
    t.datetime "updated_at",                                          null: false
    t.text     "award_number",       limit: 65535
  end

  add_index "dcs_contributors", ["name_identifier_id"], name: "index_dcs_contributors_on_name_identifier_id", using: :btree
  add_index "dcs_contributors", ["resource_id"], name: "index_dcs_contributors_on_resource_id", using: :btree

  create_table "dcs_dates", force: :cascade do |t|
    t.string   "date",        limit: 255
    t.string   "date_type",   limit: 11
    t.integer  "resource_id", limit: 4
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "dcs_dates", ["resource_id"], name: "index_dcs_dates_on_resource_id", using: :btree

  create_table "dcs_descriptions", force: :cascade do |t|
    t.text     "description",      limit: 65535
    t.string   "description_type", limit: 17
    t.integer  "resource_id",      limit: 4
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
  end

  add_index "dcs_descriptions", ["resource_id"], name: "index_dcs_descriptions_on_resource_id", using: :btree

  create_table "dcs_formats", force: :cascade do |t|
    t.text     "format",      limit: 65535
    t.integer  "resource_id", limit: 4,     null: false
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "dcs_formats", ["resource_id"], name: "index_dcs_formats_on_resource_id", using: :btree

  create_table "dcs_geo_location_boxes", force: :cascade do |t|
    t.decimal  "sw_latitude",  precision: 10, scale: 6
    t.decimal  "ne_latitude",  precision: 10, scale: 6
    t.decimal  "sw_longitude", precision: 10, scale: 6
    t.decimal  "ne_longitude", precision: 10, scale: 6
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
  end

  create_table "dcs_geo_location_places", force: :cascade do |t|
    t.text     "geo_location_place", limit: 65535
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
  end

  create_table "dcs_geo_location_points", force: :cascade do |t|
    t.decimal  "latitude",   precision: 10, scale: 6
    t.decimal  "longitude",  precision: 10, scale: 6
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
  end

  create_table "dcs_geo_locations", force: :cascade do |t|
    t.integer  "place_id",    limit: 4
    t.integer  "point_id",    limit: 4
    t.integer  "box_id",      limit: 4
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
    t.integer  "resource_id", limit: 4
  end

  add_index "dcs_geo_locations", ["box_id"], name: "index_dcs_geo_locations_on_box_id", using: :btree
  add_index "dcs_geo_locations", ["place_id"], name: "index_dcs_geo_locations_on_place_id", using: :btree
  add_index "dcs_geo_locations", ["point_id"], name: "index_dcs_geo_locations_on_point_id", using: :btree
  add_index "dcs_geo_locations", ["resource_id"], name: "index_dcs_geo_locations_on_resource_id", using: :btree

  create_table "dcs_languages", force: :cascade do |t|
    t.text     "language",    limit: 65535
    t.integer  "resource_id", limit: 4
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "dcs_languages", ["resource_id"], name: "index_dcs_languages_on_resource_id", using: :btree

  create_table "dcs_name_identifiers", force: :cascade do |t|
    t.text     "name_identifier",        limit: 65535
    t.text     "name_identifier_scheme", limit: 65535
    t.text     "scheme_URI",             limit: 65535
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
  end

  add_index "dcs_name_identifiers", ["name_identifier"], name: "index_dcs_name_identifiers_on_name_identifier", length: {"name_identifier"=>50}, using: :btree

  create_table "dcs_publication_years", force: :cascade do |t|
    t.string   "publication_year", limit: 255
    t.integer  "resource_id",      limit: 4
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  add_index "dcs_publication_years", ["resource_id"], name: "index_dcs_publication_years_on_resource_id", using: :btree

  create_table "dcs_publishers", force: :cascade do |t|
    t.text     "publisher",   limit: 65535
    t.integer  "resource_id", limit: 4
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "dcs_publishers", ["resource_id"], name: "index_dcs_publishers_on_resource_id", using: :btree

  create_table "dcs_related_identifiers", force: :cascade do |t|
    t.text     "related_identifier",      limit: 65535
    t.string   "related_identifier_type", limit: 7
    t.string   "relation_type",           limit: 19
    t.text     "related_metadata_scheme", limit: 65535
    t.text     "scheme_URI",              limit: 65535
    t.text     "scheme_type",             limit: 65535
    t.integer  "resource_id",             limit: 4
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
  end

  add_index "dcs_related_identifiers", ["related_identifier"], name: "index_dcs_related_identifiers_on_related_identifier", length: {"related_identifier"=>50}, using: :btree
  add_index "dcs_related_identifiers", ["resource_id"], name: "index_dcs_related_identifiers_on_resource_id", using: :btree

  create_table "dcs_resource_types", force: :cascade do |t|
    t.string   "resource_type_general", limit: 19
    t.text     "resource_type",         limit: 65535
    t.integer  "resource_id",           limit: 4
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
  end

  add_index "dcs_resource_types", ["resource_id"], name: "index_dcs_resource_types_on_resource_id", using: :btree

  create_table "dcs_rights", force: :cascade do |t|
    t.text     "rights",      limit: 65535
    t.text     "rights_uri",  limit: 65535
    t.integer  "resource_id", limit: 4
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "dcs_rights", ["resource_id"], name: "index_dcs_rights_on_resource_id", using: :btree

  create_table "dcs_sizes", force: :cascade do |t|
    t.text     "size",        limit: 65535
    t.integer  "resource_id", limit: 4
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "dcs_sizes", ["resource_id"], name: "index_dcs_sizes_on_resource_id", using: :btree

  create_table "dcs_subjects", force: :cascade do |t|
    t.text     "subject",        limit: 65535
    t.text     "subject_scheme", limit: 65535
    t.text     "scheme_URI",     limit: 65535
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  add_index "dcs_subjects", ["subject"], name: "index_dcs_subjects_on_subject", length: {"subject"=>50}, using: :btree

  create_table "dcs_subjects_stash_engine_resources", force: :cascade do |t|
    t.integer  "resource_id", limit: 4
    t.integer  "subject_id",  limit: 4
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  add_index "dcs_subjects_stash_engine_resources", ["resource_id"], name: "index_dcs_subjects_stash_engine_resources_on_resource_id", using: :btree
  add_index "dcs_subjects_stash_engine_resources", ["subject_id"], name: "index_dcs_subjects_stash_engine_resources_on_subject_id", using: :btree

  create_table "dcs_versions", force: :cascade do |t|
    t.string   "version",     limit: 255
    t.integer  "resource_id", limit: 4
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "dcs_versions", ["resource_id"], name: "index_dcs_versions_on_resource_id", using: :btree

  create_table "oauth_access_grants", force: :cascade do |t|
    t.integer  "resource_owner_id", limit: 4,     null: false
    t.integer  "application_id",    limit: 4,     null: false
    t.string   "token",             limit: 191,   null: false
    t.integer  "expires_in",        limit: 4,     null: false
    t.text     "redirect_uri",      limit: 65535, null: false
    t.datetime "created_at",                      null: false
    t.datetime "revoked_at"
    t.string   "scopes",            limit: 191
  end

  add_index "oauth_access_grants", ["application_id"], name: "fk_rails_b4b53e07b8", using: :btree
  add_index "oauth_access_grants", ["token"], name: "index_oauth_access_grants_on_token", unique: true, using: :btree

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.integer  "resource_owner_id",      limit: 4
    t.integer  "application_id",         limit: 4
    t.string   "token",                  limit: 191,              null: false
    t.string   "refresh_token",          limit: 191
    t.integer  "expires_in",             limit: 4
    t.datetime "revoked_at"
    t.datetime "created_at",                                      null: false
    t.string   "scopes",                 limit: 191
    t.string   "previous_refresh_token", limit: 191, default: "", null: false
  end

  add_index "oauth_access_tokens", ["application_id"], name: "fk_rails_732cb83ab7", using: :btree
  add_index "oauth_access_tokens", ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true, using: :btree
  add_index "oauth_access_tokens", ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id", using: :btree
  add_index "oauth_access_tokens", ["token"], name: "index_oauth_access_tokens_on_token", unique: true, using: :btree

  create_table "oauth_applications", force: :cascade do |t|
    t.string   "name",         limit: 191,                null: false
    t.string   "uid",          limit: 191,                null: false
    t.string   "secret",       limit: 191,                null: false
    t.text     "redirect_uri", limit: 65535,              null: false
    t.string   "scopes",       limit: 191,   default: "", null: false
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
  end

  add_index "oauth_applications", ["uid"], name: "index_oauth_applications_on_uid", unique: true, using: :btree

  create_table "searches", force: :cascade do |t|
    t.text     "query_params", limit: 65535
    t.integer  "user_id",      limit: 4
    t.string   "user_type",    limit: 255
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "searches", ["user_id"], name: "index_searches_on_user_id", using: :btree

  create_table "stash_engine_authors", force: :cascade do |t|
    t.string   "author_first_name", limit: 255
    t.string   "author_last_name",  limit: 255
    t.string   "author_email",      limit: 255
    t.string   "author_orcid",      limit: 255
    t.integer  "resource_id",       limit: 4
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  add_index "stash_engine_authors", ["author_orcid"], name: "index_stash_engine_authors_on_author_orcid", length: {"author_orcid"=>20}, using: :btree
  add_index "stash_engine_authors", ["resource_id"], name: "index_stash_engine_authors_on_resource_id", using: :btree

  create_table "stash_engine_edit_histories", force: :cascade do |t|
    t.integer  "resource_id",  limit: 4
    t.text     "user_comment", limit: 65535
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "stash_engine_edit_histories", ["resource_id"], name: "index_stash_engine_edit_histories_on_resource_id", using: :btree

  create_table "stash_engine_embargoes", force: :cascade do |t|
    t.datetime "end_date"
    t.integer  "resource_id", limit: 4
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  create_table "stash_engine_file_uploads", force: :cascade do |t|
    t.text     "upload_file_name",    limit: 65535
    t.text     "upload_content_type", limit: 65535
    t.integer  "upload_file_size",    limit: 8
    t.integer  "resource_id",         limit: 4
    t.datetime "upload_updated_at"
    t.datetime "created_at",                                        null: false
    t.datetime "updated_at",                                        null: false
    t.text     "temp_file_path",      limit: 65535
    t.string   "file_state",          limit: 7
    t.text     "url",                 limit: 65535
    t.integer  "status_code",         limit: 4
    t.boolean  "timed_out",                         default: false
    t.text     "original_url",        limit: 65535
    t.string   "cloud_service",       limit: 255
  end

  add_index "stash_engine_file_uploads", ["file_state"], name: "index_stash_engine_file_uploads_on_file_state", using: :btree
  add_index "stash_engine_file_uploads", ["resource_id"], name: "index_stash_engine_file_uploads_on_resource_id", using: :btree
  add_index "stash_engine_file_uploads", ["upload_file_name"], name: "index_stash_engine_file_uploads_on_upload_file_name", length: {"upload_file_name"=>100}, using: :btree
  add_index "stash_engine_file_uploads", ["url"], name: "index_stash_engine_file_uploads_on_url", length: {"url"=>50}, using: :btree

  create_table "stash_engine_identifiers", force: :cascade do |t|
    t.text     "identifier",      limit: 65535
    t.text     "identifier_type", limit: 65535
    t.integer  "storage_size",    limit: 8
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  add_index "stash_engine_identifiers", ["identifier"], name: "index_stash_engine_identifiers_on_identifier", length: {"identifier"=>50}, using: :btree

  create_table "stash_engine_orcid_invitations", force: :cascade do |t|
    t.string   "email",         limit: 191
    t.integer  "identifier_id", limit: 4
    t.string   "first_name",    limit: 191
    t.string   "last_name",     limit: 191
    t.string   "secret",        limit: 191
    t.string   "orcid",         limit: 191
    t.datetime "invited_at",                null: false
    t.datetime "accepted_at"
  end

  add_index "stash_engine_orcid_invitations", ["email"], name: "index_stash_engine_orcid_invitations_on_email", using: :btree
  add_index "stash_engine_orcid_invitations", ["identifier_id"], name: "index_stash_engine_orcid_invitations_on_identifier_id", using: :btree
  add_index "stash_engine_orcid_invitations", ["orcid"], name: "index_stash_engine_orcid_invitations_on_orcid", using: :btree
  add_index "stash_engine_orcid_invitations", ["secret"], name: "index_stash_engine_orcid_invitations_on_secret", using: :btree

  create_table "stash_engine_resource_states", force: :cascade do |t|
    t.integer  "user_id",        limit: 4
    t.string   "resource_state", limit: 11
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.integer  "resource_id",    limit: 4
  end

  add_index "stash_engine_resource_states", ["resource_state"], name: "index_stash_engine_resource_states_on_resource_state", using: :btree
  add_index "stash_engine_resource_states", ["user_id"], name: "index_stash_engine_resource_states_on_user_id", using: :btree

  create_table "stash_engine_resource_usages", force: :cascade do |t|
    t.integer "resource_id", limit: 4
    t.integer "downloads",   limit: 4
    t.integer "views",       limit: 4
  end

  add_index "stash_engine_resource_usages", ["resource_id"], name: "index_stash_engine_resource_usages_on_resource_id", using: :btree

  create_table "stash_engine_resources", force: :cascade do |t|
    t.integer  "user_id",                   limit: 4
    t.integer  "current_resource_state_id", limit: 4
    t.datetime "created_at",                                              null: false
    t.datetime "updated_at",                                              null: false
    t.boolean  "has_geolocation",                         default: false
    t.text     "download_uri",              limit: 65535
    t.integer  "identifier_id",             limit: 4
    t.text     "update_uri",                limit: 65535
    t.text     "title",                     limit: 65535
    t.integer  "current_editor_id",         limit: 4
    t.datetime "publication_date"
    t.boolean  "accepted_agreement"
    t.string   "tenant_id",                 limit: 100
  end

  add_index "stash_engine_resources", ["current_editor_id"], name: "index_stash_engine_resources_on_current_editor_id", using: :btree
  add_index "stash_engine_resources", ["identifier_id"], name: "index_stash_engine_resources_on_identifier_id", using: :btree

  create_table "stash_engine_shares", force: :cascade do |t|
    t.string   "secret_id",   limit: 255
    t.integer  "resource_id", limit: 4
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "stash_engine_shares", ["secret_id"], name: "index_stash_engine_shares_on_secret_id", length: {"secret_id"=>50}, using: :btree

  create_table "stash_engine_submission_logs", force: :cascade do |t|
    t.integer  "resource_id",                limit: 4
    t.text     "archive_response",           limit: 65535
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.text     "archive_submission_request", limit: 65535
  end

  add_index "stash_engine_submission_logs", ["resource_id"], name: "index_stash_engine_submission_logs_on_resource_id", using: :btree

  create_table "stash_engine_users", force: :cascade do |t|
    t.text     "first_name",  limit: 65535
    t.text     "last_name",   limit: 65535
    t.text     "email",       limit: 65535
    t.text     "uid",         limit: 65535
    t.text     "provider",    limit: 65535
    t.text     "oauth_token", limit: 65535
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.text     "tenant_id",   limit: 65535
    t.datetime "last_login"
    t.string   "role",        limit: 9,     default: "user"
    t.string   "orcid",       limit: 255
  end

  add_index "stash_engine_users", ["email"], name: "index_stash_engine_users_on_email", length: {"email"=>50}, using: :btree
  add_index "stash_engine_users", ["tenant_id"], name: "index_stash_engine_users_on_tenant_id", length: {"tenant_id"=>50}, using: :btree
  add_index "stash_engine_users", ["uid"], name: "index_stash_engine_users_on_uid", length: {"uid"=>50}, using: :btree

  create_table "stash_engine_versions", force: :cascade do |t|
    t.integer  "version",         limit: 4
    t.text     "zip_filename",    limit: 65535
    t.integer  "resource_id",     limit: 4
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.integer  "merritt_version", limit: 4
  end

  add_index "stash_engine_versions", ["resource_id"], name: "index_stash_engine_versions_on_resource_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                  limit: 191, default: "",    null: false
    t.string   "encrypted_password",     limit: 255, default: "",    null: false
    t.string   "reset_password_token",   limit: 191
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

  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
end
