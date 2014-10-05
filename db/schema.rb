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

ActiveRecord::Schema.define(:version => 20141002085309) do

  create_table "audio_recording_versions", :force => true do |t|
    t.integer  "audio_recording_id"
    t.integer  "version"
    t.string   "title",                  :limit => 510
    t.text     "description"
    t.text     "extended_content"
    t.string   "filename",               :limit => 510
    t.string   "content_type",           :limit => 510
    t.integer  "size"
    t.integer  "basket_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "parent_id"
    t.string   "raw_tag_list",           :limit => 510
    t.string   "version_comment",        :limit => 510
    t.boolean  "private"
    t.text     "related_items_position"
  end

  add_index "audio_recording_versions", ["audio_recording_id"], :name => "audio_recording_versions_audio_recording_id_idx"
  add_index "audio_recording_versions", ["basket_id"], :name => "audio_recording_versions_basket_id_idx"

  create_table "audio_recordings", :force => true do |t|
    t.string   "title",                      :limit => 510, :null => false
    t.text     "description"
    t.text     "extended_content"
    t.string   "filename",                   :limit => 510, :null => false
    t.string   "content_type",               :limit => 510, :null => false
    t.integer  "size",                                      :null => false
    t.integer  "basket_id",                                 :null => false
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.integer  "version"
    t.integer  "parent_id"
    t.string   "raw_tag_list",               :limit => 510
    t.string   "version_comment",            :limit => 510
    t.boolean  "private"
    t.boolean  "file_private"
    t.text     "private_version_serialized"
    t.integer  "license_id"
    t.text     "related_items_position"
  end

  add_index "audio_recordings", ["basket_id"], :name => "audio_recordings_basket_id_idx"

  create_table "baskets", :force => true do |t|
    t.string   "name",                               :limit => 510,                       :null => false
    t.string   "urlified_name",                      :limit => 510
    t.text     "extended_content"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "index_page_redirect_to_all",         :limit => 510
    t.boolean  "index_page_topic_is_entire_page"
    t.string   "index_page_link_to_index_topic_as",  :limit => 510
    t.boolean  "index_page_basket_search"
    t.string   "index_page_image_as",                :limit => 510
    t.string   "index_page_tags_as",                 :limit => 510
    t.integer  "index_page_number_of_tags",                         :default => 0
    t.string   "index_page_order_tags_by",           :limit => 510, :default => "number"
    t.string   "index_page_recent_topics_as",        :limit => 510
    t.integer  "index_page_number_of_recent_topics",                :default => 0
    t.string   "index_page_archives_as",             :limit => 510
    t.text     "index_page_extra_side_bar_html"
    t.boolean  "private_default"
    t.boolean  "file_private_default"
    t.boolean  "allow_non_member_comments"
    t.boolean  "show_privacy_controls"
    t.string   "status",                             :limit => 510
    t.integer  "creator_id"
  end

  create_table "bdrb_job_queues", :force => true do |t|
    t.binary   "args"
    t.string   "worker_name",    :limit => 510
    t.string   "worker_method",  :limit => 510
    t.string   "job_key",        :limit => 510
    t.integer  "taken"
    t.integer  "finished"
    t.integer  "timeout"
    t.integer  "priority"
    t.datetime "submitted_at"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "archived_at"
    t.string   "tag",            :limit => 510
    t.string   "submitter_info", :limit => 510
    t.string   "runner_info",    :limit => 510
    t.string   "worker_key",     :limit => 510
    t.datetime "scheduled_at"
  end

  create_table "brain_busters", :force => true do |t|
    t.string "question", :limit => 510
    t.string "answer",   :limit => 510
  end

  create_table "choice_mappings", :force => true do |t|
    t.integer "choice_id"
    t.integer "field_id"
    t.string  "field_type", :limit => 510
  end

  create_table "choices", :force => true do |t|
    t.string  "label",     :limit => 510
    t.string  "value",     :limit => 510
    t.integer "parent_id"
    t.integer "lft"
    t.integer "rgt"
    t.string  "data",      :limit => 510
  end

  create_table "comment_versions", :force => true do |t|
    t.integer  "comment_id"
    t.integer  "version"
    t.string   "title",            :limit => 510
    t.text     "description"
    t.text     "extended_content"
    t.integer  "position"
    t.integer  "basket_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "raw_tag_list",     :limit => 510
    t.string   "version_comment",  :limit => 510
  end

  add_index "comment_versions", ["basket_id"], :name => "comment_versions_basket_id_idx"
  add_index "comment_versions", ["comment_id"], :name => "comment_versions_comment_id_idx"

  create_table "comments", :force => true do |t|
    t.string   "title",               :limit => 510, :null => false
    t.text     "description"
    t.text     "extended_content"
    t.integer  "commentable_id",                     :null => false
    t.string   "commentable_type",    :limit => 510, :null => false
    t.integer  "basket_id",                          :null => false
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
    t.integer  "version"
    t.string   "raw_tag_list",        :limit => 510
    t.string   "version_comment",     :limit => 510
    t.boolean  "commentable_private"
    t.integer  "parent_id"
    t.integer  "lft"
    t.integer  "rgt"
  end

  add_index "comments", ["basket_id"], :name => "comments_basket_id_idx"

  create_table "configurable_settings", :force => true do |t|
    t.integer "configurable_id"
    t.string  "configurable_type", :limit => 510
    t.integer "targetable_id"
    t.string  "targetable_type",   :limit => 510
    t.string  "name",              :limit => 510, :null => false
    t.string  "value_type",        :limit => 510
    t.text    "value"
  end

  create_table "content_item_relations", :force => true do |t|
    t.integer  "position",                         :null => false
    t.integer  "topic_id",                         :null => false
    t.integer  "related_item_id",                  :null => false
    t.string   "related_item_type", :limit => 510, :null => false
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
  end

  add_index "content_item_relations", ["related_item_id"], :name => "index_content_item_relations_on_related_item_id"
  add_index "content_item_relations", ["related_item_type"], :name => "index_content_item_relations_on_related_item_type"
  add_index "content_item_relations", ["topic_id"], :name => "index_content_item_relations_on_topic_id"

  create_table "content_type_to_field_mappings", :force => true do |t|
    t.integer  "content_type_id",   :null => false
    t.integer  "extended_field_id", :null => false
    t.integer  "position",          :null => false
    t.boolean  "required"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
    t.boolean  "embedded"
    t.boolean  "private_only"
  end

  add_index "content_type_to_field_mappings", ["content_type_id"], :name => "content_type_to_field_mappings_content_type_id_idx"
  add_index "content_type_to_field_mappings", ["extended_field_id"], :name => "content_type_to_field_mappings_extended_field_id_idx"

  create_table "content_types", :force => true do |t|
    t.string "class_name",       :limit => 510, :null => false
    t.string "controller",       :limit => 510, :null => false
    t.string "humanized",        :limit => 510, :null => false
    t.string "humanized_plural", :limit => 510, :null => false
    t.text   "description",                     :null => false
  end

  create_table "contributions", :force => true do |t|
    t.integer  "user_id",                              :null => false
    t.integer  "contributed_item_id",                  :null => false
    t.string   "contributed_item_type", :limit => 510, :null => false
    t.string   "contributor_role",      :limit => 510, :null => false
    t.integer  "version",                              :null => false
    t.datetime "created_at",                           :null => false
    t.datetime "updated_at",                           :null => false
    t.text     "email_for_anonymous"
    t.text     "name_for_anonymous"
    t.text     "website_for_anonymous"
  end

  add_index "contributions", ["user_id"], :name => "contributions_user_id_idx"

  create_table "deleted_content_item_relations", :force => true do |t|
    t.integer  "position"
    t.integer  "topic_id"
    t.integer  "related_item_id"
    t.string   "related_item_type", :limit => 510
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "deleted_content_item_relations", ["related_item_id"], :name => "index_deleted_content_item_relations_on_related_item_id"
  add_index "deleted_content_item_relations", ["related_item_type"], :name => "index_deleted_content_item_relations_on_related_item_type"
  add_index "deleted_content_item_relations", ["topic_id"], :name => "index_deleted_content_item_relations_on_topic_id"

  create_table "document_versions", :force => true do |t|
    t.integer  "document_id"
    t.integer  "version"
    t.string   "title",                  :limit => 510
    t.text     "description"
    t.text     "extended_content"
    t.string   "filename",               :limit => 510
    t.string   "content_type",           :limit => 510
    t.integer  "size"
    t.integer  "basket_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "parent_id"
    t.text     "short_summary"
    t.string   "raw_tag_list",           :limit => 510
    t.string   "version_comment",        :limit => 510
    t.boolean  "private"
    t.text     "related_items_position"
  end

  add_index "document_versions", ["basket_id"], :name => "document_versions_basket_id_idx"
  add_index "document_versions", ["document_id"], :name => "document_versions_document_id_idx"

  create_table "documents", :force => true do |t|
    t.string   "title",                      :limit => 510, :null => false
    t.text     "description"
    t.text     "extended_content"
    t.string   "filename",                   :limit => 510, :null => false
    t.string   "content_type",               :limit => 510, :null => false
    t.integer  "size",                                      :null => false
    t.integer  "basket_id",                                 :null => false
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.integer  "version"
    t.integer  "parent_id"
    t.text     "short_summary"
    t.string   "raw_tag_list",               :limit => 510
    t.string   "version_comment",            :limit => 510
    t.boolean  "file_private"
    t.boolean  "private"
    t.text     "private_version_serialized"
    t.integer  "license_id"
    t.text     "related_items_position"
  end

  add_index "documents", ["basket_id"], :name => "documents_basket_id_idx"

  create_table "extended_fields", :force => true do |t|
    t.string   "label",                   :limit => 510,                     :null => false
    t.string   "xml_element_name",        :limit => 510
    t.string   "xsi_type",                :limit => 510
    t.boolean  "multiple"
    t.text     "description"
    t.string   "example",                 :limit => 510
    t.string   "ftype",                   :limit => 30,  :default => "text"
    t.datetime "created_at",                                                 :null => false
    t.datetime "updated_at",                                                 :null => false
    t.text     "import_synonyms"
    t.boolean  "user_choice_addition"
    t.boolean  "dont_link_choice_values"
  end

  create_table "feeds", :force => true do |t|
    t.string   "title",            :limit => 510
    t.string   "url",              :limit => 510
    t.integer  "limit"
    t.integer  "basket_id"
    t.datetime "last_downloaded"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "serialized_feed"
    t.float    "update_frequency"
  end

  add_index "feeds", ["basket_id"], :name => "feeds_basket_id_idx"

  create_table "image_files", :force => true do |t|
    t.integer "still_image_id"
    t.integer "parent_id"
    t.string  "thumbnail",      :limit => 510
    t.string  "filename",       :limit => 510, :null => false
    t.string  "content_type",   :limit => 510, :null => false
    t.integer "size",                          :null => false
    t.integer "width"
    t.integer "height"
    t.boolean "file_private"
  end

  add_index "image_files", ["still_image_id"], :name => "image_files_still_image_id_idx"

  create_table "import_archive_files", :force => true do |t|
    t.string   "filename",     :limit => 510
    t.string   "content_type", :limit => 510
    t.integer  "size"
    t.integer  "import_id"
    t.integer  "parent_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "import_archive_files", ["import_id"], :name => "import_archive_files_import_id_idx"

  create_table "imports", :force => true do |t|
    t.text     "status"
    t.integer  "records_processed"
    t.integer  "interval_between_records",                                                :null => false
    t.text     "default_description_end_template"
    t.text     "description_beginning_template"
    t.text     "xml_type",                                                                :null => false
    t.text     "xml_path_to_record"
    t.text     "directory",                                                               :null => false
    t.integer  "topic_type_id"
    t.integer  "basket_id",                                                               :null => false
    t.integer  "user_id",                                                                 :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "base_tags",                                                :limit => 510
    t.integer  "license_id"
    t.boolean  "private"
    t.integer  "related_topic_type_id"
    t.integer  "extended_field_that_contains_record_identifier_id"
    t.string   "record_identifier_xml_field",                              :limit => 510
    t.string   "related_topics_reference_in_record_xml_field",             :limit => 510
    t.integer  "extended_field_that_contains_related_topics_reference_id"
    t.boolean  "file_private"
  end

  add_index "imports", ["basket_id"], :name => "imports_basket_id_idx"
  add_index "imports", ["topic_type_id"], :name => "imports_topic_type_id_idx"
  add_index "imports", ["user_id"], :name => "imports_user_id_idx"

  create_table "licenses", :force => true do |t|
    t.string   "name",                :limit => 510
    t.string   "description",         :limit => 510
    t.string   "url",                 :limit => 510
    t.boolean  "is_available"
    t.string   "image_url",           :limit => 510
    t.boolean  "is_creative_commons"
    t.text     "metadata"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "oai_pmh_repository_sets", :force => true do |t|
    t.integer  "zoom_db_id"
    t.string   "name",        :limit => 510, :null => false
    t.string   "set_spec",    :limit => 510, :null => false
    t.string   "match_code",  :limit => 510, :null => false
    t.string   "value",       :limit => 510, :null => false
    t.string   "description", :limit => 510
    t.boolean  "active"
    t.boolean  "dynamic"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "oai_pmh_repository_sets", ["zoom_db_id"], :name => "oai_pmh_repository_sets_zoom_db_id_idx"

  create_table "pg_search_documents", :force => true do |t|
    t.text     "content"
    t.integer  "searchable_id"
    t.string   "searchable_type"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  create_table "profile_mappings", :force => true do |t|
    t.integer  "profile_id",                                           :null => false
    t.integer  "profilable_id",                                        :null => false
    t.string   "profilable_type", :limit => 510, :default => "Basket"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "profile_mappings", ["profile_id"], :name => "profile_mappings_profile_id_idx"

  create_table "profiles", :force => true do |t|
    t.string   "name",                :limit => 510, :null => false
    t.string   "available_to_models", :limit => 510, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "redirect_registrations", :force => true do |t|
    t.text     "source_url_pattern",                  :null => false
    t.text     "target_url_pattern",                  :null => false
    t.integer  "status_code",        :default => 301, :null => false
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
  end

  create_table "roles", :force => true do |t|
    t.string   "name",              :limit => 80
    t.string   "authorizable_type", :limit => 60
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

  add_index "roles_users", ["role_id"], :name => "roles_users_role_id_idx"
  add_index "roles_users", ["user_id"], :name => "roles_users_user_id_idx"

  create_table "search_sources", :force => true do |t|
    t.string   "title",              :limit => 510
    t.string   "source_type",        :limit => 510
    t.string   "base_url",           :limit => 510
    t.string   "more_link_base_url", :limit => 510
    t.integer  "limit"
    t.integer  "cache_interval"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "position"
    t.string   "source_target",      :limit => 510
    t.string   "limit_param",        :limit => 510
    t.text     "or_syntax"
    t.text     "and_syntax"
    t.text     "not_syntax"
    t.text     "source_credit"
  end

  create_table "searches", :force => true do |t|
    t.integer  "user_id",                   :null => false
    t.string   "title",      :limit => 510, :null => false
    t.string   "url",        :limit => 510, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "searches", ["user_id"], :name => "searches_user_id_idx"

  create_table "still_image_versions", :force => true do |t|
    t.integer  "still_image_id"
    t.integer  "version"
    t.string   "title",                  :limit => 510
    t.text     "description"
    t.text     "extended_content"
    t.integer  "basket_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "raw_tag_list",           :limit => 510
    t.string   "version_comment",        :limit => 510
    t.boolean  "private"
    t.text     "related_items_position"
  end

  add_index "still_image_versions", ["basket_id"], :name => "still_image_versions_basket_id_idx"
  add_index "still_image_versions", ["still_image_id"], :name => "still_image_versions_still_image_id_idx"

  create_table "still_images", :force => true do |t|
    t.string   "title",                      :limit => 510, :null => false
    t.text     "description"
    t.text     "extended_content"
    t.integer  "basket_id",                                 :null => false
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.integer  "version"
    t.string   "raw_tag_list",               :limit => 510
    t.string   "version_comment",            :limit => 510
    t.boolean  "private"
    t.boolean  "file_private"
    t.text     "private_version_serialized"
    t.integer  "license_id"
    t.text     "related_items_position"
  end

  add_index "still_images", ["basket_id"], :name => "still_images_basket_id_idx"

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id",                       :null => false
    t.integer  "taggable_id",                  :null => false
    t.string   "taggable_type", :limit => 510, :null => false
    t.datetime "created_at"
    t.text     "message"
    t.string   "context",       :limit => 510
    t.integer  "basket_id"
    t.integer  "tagger_id"
    t.string   "tagger_type",   :limit => 510
  end

  add_index "taggings", ["basket_id"], :name => "taggings_basket_id_idx"
  add_index "taggings", ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], :name => "taggings_idx", :unique => true
  add_index "taggings", ["taggable_id", "taggable_type", "context"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_context"

  create_table "tags", :force => true do |t|
    t.string  "name",           :limit => 510,                :null => false
    t.integer "taggings_count",                :default => 0
  end

  create_table "topic_type_to_field_mappings", :force => true do |t|
    t.integer  "topic_type_id",     :null => false
    t.integer  "extended_field_id", :null => false
    t.integer  "position",          :null => false
    t.boolean  "required"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
    t.boolean  "embedded"
    t.boolean  "private_only"
  end

  add_index "topic_type_to_field_mappings", ["extended_field_id"], :name => "topic_type_to_field_mappings_extended_field_id_idx"
  add_index "topic_type_to_field_mappings", ["topic_type_id"], :name => "topic_type_to_field_mappings_topic_type_id_idx"

  create_table "topic_types", :force => true do |t|
    t.string   "name",        :limit => 510, :null => false
    t.text     "description",                :null => false
    t.integer  "parent_id"
    t.integer  "lft"
    t.integer  "rgt"
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
  end

  create_table "topic_versions", :force => true do |t|
    t.integer  "topic_id"
    t.integer  "version"
    t.string   "title",                  :limit => 510
    t.text     "short_summary"
    t.text     "description"
    t.text     "extended_content"
    t.integer  "topic_type_id"
    t.integer  "basket_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "raw_tag_list",           :limit => 510
    t.string   "version_comment",        :limit => 510
    t.integer  "index_for_basket_id"
    t.boolean  "private"
    t.text     "related_items_position"
  end

  add_index "topic_versions", ["basket_id"], :name => "topic_versions_basket_id_idx"
  add_index "topic_versions", ["topic_id"], :name => "topic_versions_topic_id_idx"
  add_index "topic_versions", ["topic_type_id"], :name => "topic_versions_topic_type_id_idx"

  create_table "topics", :force => true do |t|
    t.string   "title",                      :limit => 510, :null => false
    t.text     "short_summary"
    t.text     "description"
    t.text     "extended_content"
    t.integer  "topic_type_id",                             :null => false
    t.integer  "basket_id",                                 :null => false
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.integer  "version"
    t.string   "raw_tag_list",               :limit => 510
    t.string   "version_comment",            :limit => 510
    t.integer  "index_for_basket_id"
    t.boolean  "private"
    t.text     "private_version_serialized"
    t.integer  "license_id"
    t.text     "related_items_position"
  end

  add_index "topics", ["basket_id"], :name => "topics_basket_id_idx"
  add_index "topics", ["index_for_basket_id"], :name => "topics_index_for_basket_id_idx"
  add_index "topics", ["topic_type_id"], :name => "topics_topic_type_id_idx"

  create_table "user_portrait_relations", :force => true do |t|
    t.integer  "position"
    t.integer  "user_id"
    t.integer  "still_image_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_portrait_relations", ["still_image_id"], :name => "user_portrait_relations_still_image_id_idx"
  add_index "user_portrait_relations", ["user_id"], :name => "user_portrait_relations_user_id_idx"

  create_table "users", :force => true do |t|
    t.string   "login",                     :limit => 510
    t.string   "email",                     :limit => 510
    t.string   "crypted_password",          :limit => 80
    t.string   "salt",                      :limit => 80
    t.text     "extended_content"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token",            :limit => 510
    t.datetime "remember_token_expires_at"
    t.string   "activation_code",           :limit => 80
    t.datetime "activated_at"
    t.string   "password_reset_code",       :limit => 80
    t.datetime "banned_at"
    t.integer  "license_id"
    t.boolean  "allow_emails"
    t.string   "display_name",              :limit => 510
    t.string   "resolved_name",             :limit => 510, :null => false
    t.string   "locale",                    :limit => 510
  end

  create_table "video_versions", :force => true do |t|
    t.integer  "video_id"
    t.integer  "version"
    t.string   "title",                  :limit => 510
    t.text     "description"
    t.text     "extended_content"
    t.string   "filename",               :limit => 510
    t.string   "content_type",           :limit => 510
    t.integer  "size"
    t.integer  "basket_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "parent_id"
    t.string   "raw_tag_list",           :limit => 510
    t.string   "version_comment",        :limit => 510
    t.boolean  "private"
    t.text     "related_items_position"
  end

  add_index "video_versions", ["basket_id"], :name => "video_versions_basket_id_idx"
  add_index "video_versions", ["video_id"], :name => "video_versions_video_id_idx"

  create_table "videos", :force => true do |t|
    t.string   "title",                      :limit => 510, :null => false
    t.text     "description"
    t.text     "extended_content"
    t.string   "filename",                   :limit => 510, :null => false
    t.string   "content_type",               :limit => 510, :null => false
    t.integer  "size",                                      :null => false
    t.integer  "basket_id",                                 :null => false
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.integer  "version"
    t.integer  "parent_id"
    t.string   "raw_tag_list",               :limit => 510
    t.string   "version_comment",            :limit => 510
    t.boolean  "private"
    t.boolean  "file_private"
    t.text     "private_version_serialized"
    t.integer  "license_id"
    t.text     "related_items_position"
  end

  add_index "videos", ["basket_id"], :name => "videos_basket_id_idx"

  create_table "web_link_versions", :force => true do |t|
    t.integer  "web_link_id"
    t.integer  "version"
    t.string   "title",                  :limit => 510
    t.text     "description"
    t.string   "url",                    :limit => 510
    t.text     "extended_content"
    t.integer  "basket_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "raw_tag_list",           :limit => 510
    t.string   "version_comment",        :limit => 510
    t.boolean  "private"
    t.text     "related_items_position"
  end

  add_index "web_link_versions", ["basket_id"], :name => "web_link_versions_basket_id_idx"
  add_index "web_link_versions", ["web_link_id"], :name => "web_link_versions_web_link_id_idx"

  create_table "web_links", :force => true do |t|
    t.string   "title",                      :limit => 510, :null => false
    t.text     "description"
    t.string   "url",                        :limit => 510, :null => false
    t.text     "extended_content"
    t.integer  "basket_id",                                 :null => false
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.integer  "version"
    t.string   "raw_tag_list",               :limit => 510
    t.string   "version_comment",            :limit => 510
    t.boolean  "private"
    t.boolean  "file_private"
    t.text     "private_version_serialized"
    t.integer  "license_id"
    t.text     "related_items_position"
  end

  add_index "web_links", ["basket_id"], :name => "web_links_basket_id_idx"

  create_table "zoom_dbs", :force => true do |t|
    t.string   "database_name", :limit => 510, :null => false
    t.text     "description"
    t.string   "host",          :limit => 510, :null => false
    t.text     "port",                         :null => false
    t.string   "zoom_user",     :limit => 510
    t.string   "zoom_password", :limit => 510
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
  end

end
