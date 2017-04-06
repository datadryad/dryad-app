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

ActiveRecord::Schema.define(version: 20161206185946) do

  create_table "stash_engine_file_uploads", force: :cascade do |t|
    t.text     "upload_file_name",    limit: 65535
    t.text     "upload_content_type", limit: 65535
    t.integer  "upload_file_size",    limit: 4
    t.integer  "resource_id",         limit: 4
    t.datetime "upload_updated_at"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.text     "temp_file_path",      limit: 65535
    t.string   "file_state",          limit: 7
  end

  add_index "stash_engine_file_uploads", ["file_state"], name: "index_stash_engine_file_uploads_on_file_state", using: :btree
  add_index "stash_engine_file_uploads", ["resource_id"], name: "index_stash_engine_file_uploads_on_resource_id", using: :btree
  add_index "stash_engine_file_uploads", ["upload_file_name"], name: "index_stash_engine_file_uploads_on_upload_file_name", length: {"upload_file_name"=>100}, using: :btree

  create_table "stash_engine_identifiers", force: :cascade do |t|
    t.text     "identifier",      limit: 65535
    t.text     "identifier_type", limit: 65535
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  add_index "stash_engine_identifiers", ["identifier"], name: "index_stash_engine_identifiers_on_identifier", length: {"identifier"=>50}, using: :btree

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
  end

  add_index "stash_engine_resources", ["identifier_id"], name: "index_stash_engine_resources_on_identifier_id", using: :btree

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
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
    t.text     "tenant_id",   limit: 65535
    t.boolean  "orcid",                     default: false
  end

  add_index "stash_engine_users", ["email"], name: "index_stash_engine_users_on_email", length: {"email"=>50}, using: :btree
  add_index "stash_engine_users", ["tenant_id"], name: "index_stash_engine_users_on_tenant_id", length: {"tenant_id"=>50}, using: :btree
  add_index "stash_engine_users", ["uid"], name: "index_stash_engine_users_on_uid", length: {"uid"=>50}, using: :btree

  create_table "stash_engine_versions", force: :cascade do |t|
    t.integer  "version",      limit: 4
    t.text     "zip_filename", limit: 65535
    t.integer  "resource_id",  limit: 4
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "stash_engine_versions", ["resource_id"], name: "index_stash_engine_versions_on_resource_id", using: :btree

end
