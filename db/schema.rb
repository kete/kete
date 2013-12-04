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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20131120235220) do

  create_table "audio_recording_versions", :force => true do |t|
    t.integer  "audio_recording_id"
    t.integer  "version"
    t.string   "title"
    t.text     "description"
    t.text     "extended_content"
    t.string   "filename"
    t.string   "content_type"
    t.integer  "size"
    t.integer  "basket_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "parent_id"
    t.string   "raw_tag_list"
    t.string   "version_comment"
    t.boolean  "private"
    t.text     "related_items_position"
  end

  add_index "audio_recording_versions", ["audio_recording_id"], :name => "index_audio_recording_versions_on_audio_recording_id"

  create_table "audio_recordings", :force => true do |t|
    t.string   "title",                      :null => false
    t.text     "description"
    t.text     "extended_content"
    t.string   "filename",                   :null => false
    t.string   "content_type",               :null => false
    t.integer  "size",                       :null => false
    t.integer  "basket_id",                  :null => false
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
    t.integer  "version"
    t.integer  "parent_id"
    t.string   "raw_tag_list"
    t.string   "version_comment"
    t.boolean  "private"
    t.boolean  "file_private"
    t.text     "private_version_serialized"
    t.integer  "license_id"
    t.text     "related_items_position"
  end

  create_table "baskets", :force => true do |t|
    t.string   "name",                                                     :null => false
    t.string   "urlified_name"
    t.text     "extended_content"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "index_page_redirect_to_all"
    t.boolean  "index_page_topic_is_entire_page",    :default => false
    t.string   "index_page_link_to_index_topic_as"
    t.boolean  "index_page_basket_search",           :default => false
    t.string   "index_page_image_as"
    t.string   "index_page_tags_as"
    t.integer  "index_page_number_of_tags",          :default => 0
    t.string   "index_page_order_tags_by",           :default => "number"
    t.string   "index_page_recent_topics_as"
    t.integer  "index_page_number_of_recent_topics", :default => 0
    t.string   "index_page_archives_as"
    t.text     "index_page_extra_side_bar_html"
    t.boolean  "private_default"
    t.boolean  "file_private_default"
    t.boolean  "allow_non_member_comments"
    t.boolean  "show_privacy_controls"
    t.string   "status"
    t.integer  "creator_id"
  end

  create_table "bdrb_job_queues", :force => true do |t|
    t.binary   "args"
    t.string   "worker_name"
    t.string   "worker_method"
    t.string   "job_key"
    t.integer  "taken"
    t.integer  "finished"
    t.integer  "timeout"
    t.integer  "priority"
    t.datetime "submitted_at"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "archived_at"
    t.string   "tag"
    t.string   "submitter_info"
    t.string   "runner_info"
    t.string   "worker_key"
    t.datetime "scheduled_at"
  end

  create_table "brain_busters", :force => true do |t|
    t.string "question"
    t.string "answer"
  end

  create_table "captchas", :force => true do |t|
    t.string   "text",       :limit => 25, :null => false
    t.binary   "imageblob",                :null => false
    t.datetime "created_at",               :null => false
  end

  create_table "choice_mappings", :force => true do |t|
    t.integer "choice_id"
    t.integer "field_id"
    t.string  "field_type"
  end

  create_table "choices", :force => true do |t|
    t.string  "label"
    t.string  "value"
    t.integer "parent_id"
    t.integer "lft"
    t.integer "rgt"
    t.string  "data"
  end

  create_table "comment_versions", :force => true do |t|
    t.integer  "comment_id"
    t.integer  "version"
    t.string   "title"
    t.text     "description"
    t.text     "extended_content"
    t.integer  "position"
    t.integer  "basket_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "raw_tag_list"
    t.string   "version_comment"
  end

  add_index "comment_versions", ["comment_id"], :name => "index_comment_versions_on_comment_id"

  create_table "comments", :force => true do |t|
    t.string   "title",               :null => false
    t.text     "description"
    t.text     "extended_content"
    t.integer  "commentable_id",      :null => false
    t.string   "commentable_type",    :null => false
    t.integer  "basket_id",           :null => false
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
    t.integer  "version"
    t.string   "raw_tag_list"
    t.string   "version_comment"
    t.boolean  "commentable_private"
    t.integer  "parent_id"
    t.integer  "lft"
    t.integer  "rgt"
  end

  create_table "content_item_relations", :id => false, :force => true do |t|
    t.integer  "id",                :null => false
    t.integer  "position",          :null => false
    t.integer  "topic_id",          :null => false
    t.integer  "related_item_id",   :null => false
    t.string   "related_item_type", :null => false
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  add_index "content_item_relations", ["related_item_id"], :name => "index_content_item_relations_on_related_item_id"

  create_table "content_type_to_field_mappings", :force => true do |t|
    t.integer  "content_type_id",                      :null => false
    t.integer  "extended_field_id",                    :null => false
    t.integer  "position",                             :null => false
    t.boolean  "required",          :default => false
    t.datetime "created_at",                           :null => false
    t.datetime "updated_at",                           :null => false
    t.boolean  "embedded"
    t.boolean  "private_only"
  end

  create_table "content_types", :force => true do |t|
    t.string "class_name",       :null => false
    t.string "controller",       :null => false
    t.string "humanized",        :null => false
    t.string "humanized_plural", :null => false
    t.text   "description",      :null => false
  end

  create_table "contributions", :force => true do |t|
    t.integer  "user_id",               :null => false
    t.integer  "contributed_item_id",   :null => false
    t.string   "contributed_item_type", :null => false
    t.string   "contributor_role",      :null => false
    t.integer  "version",               :null => false
    t.datetime "created_at",            :null => false
    t.datetime "updated_at",            :null => false
    t.text     "email_for_anonymous"
    t.text     "name_for_anonymous"
    t.text     "website_for_anonymous"
  end

  add_index "contributions", ["contributed_item_id"], :name => "index_contributions_on_contributed_item_id"

  create_table "deleted_content_item_relations", :id => false, :force => true do |t|
    t.integer  "id",                :null => false
    t.integer  "position"
    t.integer  "topic_id"
    t.integer  "related_item_id"
    t.string   "related_item_type"
    t.datetime "deleted_at"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  create_table "document_versions", :force => true do |t|
    t.integer  "document_id"
    t.integer  "version"
    t.string   "title"
    t.text     "description"
    t.text     "extended_content"
    t.string   "filename"
    t.string   "content_type"
    t.integer  "size"
    t.integer  "basket_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "parent_id"
    t.text     "short_summary"
    t.string   "raw_tag_list"
    t.string   "version_comment"
    t.boolean  "private"
    t.text     "related_items_position"
  end

  add_index "document_versions", ["document_id"], :name => "index_document_versions_on_document_id"

  create_table "documents", :force => true do |t|
    t.string   "title",                      :null => false
    t.text     "description"
    t.text     "extended_content"
    t.string   "filename",                   :null => false
    t.string   "content_type",               :null => false
    t.integer  "size",                       :null => false
    t.integer  "basket_id",                  :null => false
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
    t.integer  "version"
    t.integer  "parent_id"
    t.text     "short_summary"
    t.string   "raw_tag_list"
    t.string   "version_comment"
    t.boolean  "file_private"
    t.boolean  "private"
    t.text     "private_version_serialized"
    t.integer  "license_id"
    t.text     "related_items_position"
  end

  create_table "extended_fields", :force => true do |t|
    t.string   "label",                                                     :null => false
    t.string   "xml_element_name"
    t.string   "xsi_type"
    t.boolean  "multiple",                              :default => false
    t.text     "description"
    t.datetime "created_at",                                                :null => false
    t.datetime "updated_at",                                                :null => false
    t.text     "import_synonyms"
    t.string   "example"
    t.string   "ftype",                   :limit => 15, :default => "text"
    t.boolean  "user_choice_addition"
    t.boolean  "dont_link_choice_values"
  end

  create_table "feeds", :force => true do |t|
    t.string   "title"
    t.string   "url"
    t.integer  "limit"
    t.integer  "basket_id"
    t.datetime "last_downloaded"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
    t.text     "serialized_feed"
    t.float    "update_frequency"
  end

  create_table "image_files", :force => true do |t|
    t.integer "still_image_id"
    t.integer "parent_id"
    t.string  "thumbnail"
    t.string  "filename",       :null => false
    t.string  "content_type",   :null => false
    t.integer "size",           :null => false
    t.integer "width"
    t.integer "height"
    t.boolean "file_private"
  end

  create_table "import_archive_files", :force => true do |t|
    t.string   "filename"
    t.string   "content_type"
    t.integer  "size"
    t.integer  "import_id"
    t.integer  "parent_id"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  create_table "imports", :force => true do |t|
    t.text     "status"
    t.integer  "records_processed"
    t.integer  "interval_between_records",                                                    :null => false
    t.text     "default_description_end_template"
    t.text     "description_beginning_template"
    t.text     "xml_type",                                                                    :null => false
    t.text     "xml_path_to_record"
    t.text     "directory",                                                                   :null => false
    t.integer  "topic_type_id"
    t.integer  "basket_id",                                                                   :null => false
    t.integer  "user_id",                                                                     :null => false
    t.datetime "created_at",                                                                  :null => false
    t.datetime "updated_at",                                                                  :null => false
    t.string   "base_tags"
    t.integer  "license_id"
    t.boolean  "private"
    t.integer  "related_topic_type_id"
    t.integer  "extended_field_that_contains_record_identifier_id"
    t.string   "record_identifier_xml_field"
    t.string   "related_topics_reference_in_record_xml_field"
    t.integer  "extended_field_that_contains_related_topics_reference_id"
    t.boolean  "file_private",                                             :default => false
  end

  create_table "licenses", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.string   "url"
    t.boolean  "is_available"
    t.string   "image_url"
    t.boolean  "is_creative_commons"
    t.text     "metadata"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
  end

  create_table "oai_pmh_repository_sets", :force => true do |t|
    t.integer  "zoom_db_id"
    t.string   "name",                           :null => false
    t.string   "set_spec",                       :null => false
    t.string   "match_code",                     :null => false
    t.string   "value",                          :null => false
    t.string   "description"
    t.boolean  "active",      :default => true
    t.boolean  "dynamic",     :default => false
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
  end

  create_table "profile_mappings", :force => true do |t|
    t.integer  "profile_id",                            :null => false
    t.integer  "profilable_id",                         :null => false
    t.string   "profilable_type", :default => "Basket"
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
  end

  create_table "profiles", :force => true do |t|
    t.string   "name",                :null => false
    t.string   "available_to_models", :null => false
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
  end

  create_table "redirect_registrations", :force => true do |t|
    t.text     "source_url_pattern",                  :null => false
    t.text     "target_url_pattern",                  :null => false
    t.integer  "status_code",        :default => 301, :null => false
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
  end

  create_table "roles", :force => true do |t|
    t.string   "name",              :limit => 40
    t.string   "authorizable_type", :limit => 30
    t.integer  "authorizable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer  "user_id"
    t.integer  "role_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "search_sources", :force => true do |t|
    t.string   "title"
    t.string   "source_type"
    t.string   "base_url"
    t.string   "more_link_base_url"
    t.integer  "limit"
    t.integer  "cache_interval"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
    t.integer  "position"
    t.string   "source_target"
    t.string   "limit_param"
    t.text     "or_syntax"
    t.text     "and_syntax"
    t.text     "not_syntax"
    t.text     "source_credit"
  end

  create_table "searches", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.string   "title",      :null => false
    t.string   "url",        :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "still_image_versions", :force => true do |t|
    t.integer  "still_image_id"
    t.integer  "version"
    t.string   "title"
    t.text     "description"
    t.text     "extended_content"
    t.integer  "basket_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "raw_tag_list"
    t.string   "version_comment"
    t.boolean  "private"
    t.text     "related_items_position"
  end

  add_index "still_image_versions", ["still_image_id"], :name => "index_still_image_versions_on_still_image_id"

  create_table "still_images", :force => true do |t|
    t.string   "title",                      :null => false
    t.text     "description"
    t.text     "extended_content"
    t.integer  "basket_id",                  :null => false
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
    t.integer  "version"
    t.string   "raw_tag_list"
    t.string   "version_comment"
    t.boolean  "private"
    t.boolean  "file_private"
    t.text     "private_version_serialized"
    t.integer  "license_id"
    t.text     "related_items_position"
  end

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id",        :null => false
    t.integer  "taggable_id",   :null => false
    t.string   "taggable_type", :null => false
    t.datetime "created_at"
    t.text     "message"
    t.string   "context"
    t.integer  "basket_id"
    t.integer  "tagger_id"
    t.string   "tagger_type"
  end

  add_index "taggings", ["taggable_id"], :name => "index_taggings_on_taggable_id"

  create_table "tags", :force => true do |t|
    t.string "name", :null => false
  end

  add_index "tags", ["name"], :name => "index_tags_on_name"

  create_table "topic_type_to_field_mappings", :force => true do |t|
    t.integer  "topic_type_id",                        :null => false
    t.integer  "extended_field_id",                    :null => false
    t.integer  "position",                             :null => false
    t.boolean  "required",          :default => false
    t.datetime "created_at",                           :null => false
    t.datetime "updated_at",                           :null => false
    t.boolean  "embedded"
    t.boolean  "private_only"
  end

  create_table "topic_types", :force => true do |t|
    t.string   "name",        :null => false
    t.text     "description", :null => false
    t.integer  "parent_id"
    t.integer  "lft"
    t.integer  "rgt"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "topic_versions", :force => true do |t|
    t.integer  "topic_id"
    t.integer  "version"
    t.string   "title"
    t.text     "short_summary"
    t.text     "description"
    t.text     "extended_content"
    t.integer  "topic_type_id"
    t.integer  "basket_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "raw_tag_list"
    t.string   "version_comment"
    t.integer  "index_for_basket_id"
    t.boolean  "private"
    t.text     "related_items_position"
  end

  add_index "topic_versions", ["topic_id"], :name => "index_topic_versions_on_topic_id"

  create_table "topics", :force => true do |t|
    t.string   "title",                      :null => false
    t.text     "short_summary"
    t.text     "description"
    t.text     "extended_content"
    t.integer  "topic_type_id",              :null => false
    t.integer  "basket_id",                  :null => false
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
    t.integer  "version"
    t.string   "raw_tag_list"
    t.string   "version_comment"
    t.integer  "index_for_basket_id"
    t.boolean  "private"
    t.text     "private_version_serialized"
    t.integer  "license_id"
    t.text     "related_items_position"
  end

  create_table "user_portrait_relations", :force => true do |t|
    t.integer  "position"
    t.integer  "user_id"
    t.integer  "still_image_id"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "email"
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.text     "extended_content"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.string   "activation_code",           :limit => 40
    t.datetime "activated_at"
    t.string   "password_reset_code",       :limit => 40
    t.datetime "banned_at"
    t.integer  "license_id"
    t.boolean  "allow_emails"
    t.string   "display_name"
    t.string   "resolved_name",                           :null => false
    t.string   "locale"
  end

  create_table "video_versions", :force => true do |t|
    t.integer  "video_id"
    t.integer  "version"
    t.string   "title"
    t.text     "description"
    t.text     "extended_content"
    t.string   "filename"
    t.string   "content_type"
    t.integer  "size"
    t.integer  "basket_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "parent_id"
    t.string   "raw_tag_list"
    t.string   "version_comment"
    t.boolean  "private"
    t.text     "related_items_position"
  end

  add_index "video_versions", ["video_id"], :name => "index_video_versions_on_video_id"

  create_table "videos", :force => true do |t|
    t.string   "title",                      :null => false
    t.text     "description"
    t.text     "extended_content"
    t.string   "filename",                   :null => false
    t.string   "content_type",               :null => false
    t.integer  "size",                       :null => false
    t.integer  "basket_id",                  :null => false
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
    t.integer  "version"
    t.integer  "parent_id"
    t.string   "raw_tag_list"
    t.string   "version_comment"
    t.boolean  "private"
    t.boolean  "file_private"
    t.text     "private_version_serialized"
    t.integer  "license_id"
    t.text     "related_items_position"
  end

  create_table "web_link_versions", :force => true do |t|
    t.integer  "web_link_id"
    t.integer  "version"
    t.string   "title"
    t.text     "description"
    t.string   "url"
    t.text     "extended_content"
    t.integer  "basket_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "raw_tag_list"
    t.string   "version_comment"
    t.boolean  "private"
    t.text     "related_items_position"
  end

  add_index "web_link_versions", ["web_link_id"], :name => "index_web_link_versions_on_web_link_id"

  create_table "web_links", :force => true do |t|
    t.string   "title",                      :null => false
    t.text     "description"
    t.string   "url",                        :null => false
    t.text     "extended_content"
    t.integer  "basket_id",                  :null => false
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
    t.integer  "version"
    t.string   "raw_tag_list"
    t.string   "version_comment"
    t.boolean  "private"
    t.boolean  "file_private"
    t.text     "private_version_serialized"
    t.integer  "license_id"
    t.text     "related_items_position"
  end

  create_table "zoom_dbs", :force => true do |t|
    t.string   "database_name", :null => false
    t.text     "description"
    t.string   "host",          :null => false
    t.text     "port",          :null => false
    t.string   "zoom_user"
    t.string   "zoom_password"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

end
