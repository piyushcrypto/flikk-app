# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_12_24_234608) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "availability_slots", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "day_of_week"
    t.time "start_time"
    t.time "end_time"
    t.boolean "is_active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_availability_slots_on_user_id"
  end

  create_table "conversations", force: :cascade do |t|
    t.bigint "fan_id", null: false
    t.bigint "creator_id", null: false
    t.datetime "last_message_at"
    t.integer "unread_fan_count", default: 0
    t.integer "unread_creator_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id", "last_message_at"], name: "index_conversations_creator_last_msg", order: { last_message_at: :desc }
    t.index ["creator_id"], name: "index_conversations_on_creator_id"
    t.index ["fan_id", "creator_id"], name: "index_conversations_on_fan_id_and_creator_id", unique: true
    t.index ["fan_id", "last_message_at"], name: "index_conversations_fan_last_msg", order: { last_message_at: :desc }
    t.index ["fan_id"], name: "index_conversations_on_fan_id"
    t.index ["last_message_at"], name: "index_conversations_on_last_message_at"
  end

  create_table "creator_services", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "service_type"
    t.text "description"
    t.decimal "price_per_slot"
    t.decimal "price_per_message"
    t.boolean "is_active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_creator_services_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "conversation_id", null: false
    t.bigint "sender_id", null: false
    t.text "content", null: false
    t.datetime "read_at"
    t.integer "message_type", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id", "created_at"], name: "index_messages_on_conversation_id_and_created_at"
    t.index ["conversation_id", "sender_id", "read_at"], name: "index_messages_on_conv_sender_read"
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["read_at"], name: "index_messages_on_read_at"
    t.index ["sender_id"], name: "index_messages_on_sender_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name", default: "", null: false
    t.integer "role", default: 0, null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "username"
    t.string "instagram_handle"
    t.text "bio"
    t.string "avatar_url"
    t.string "cover_url"
    t.integer "onboarding_step"
    t.boolean "onboarding_completed"
    t.boolean "is_live"
    t.datetime "last_live_at"
    t.string "category"
    t.integer "followers_count"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role", "followers_count"], name: "index_users_on_role_and_followers", order: { followers_count: :desc }
    t.index ["role", "is_live"], name: "index_users_on_role_and_live_status"
    t.index ["role", "onboarding_completed"], name: "index_users_on_role_and_onboarding"
    t.index ["role"], name: "index_users_on_role"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "availability_slots", "users"
  add_foreign_key "conversations", "users", column: "creator_id"
  add_foreign_key "conversations", "users", column: "fan_id"
  add_foreign_key "creator_services", "users"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "users", column: "sender_id"
end
