class SystemSetting < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name
  validates_length_of :name, :maximum => 255

  def self.find_by_name(name)
    first(:conditions => ["name = ?", name.to_s]) unless name.nil?
  end

  def self.[](name)
    return unless name
    setting = find_by_name(name)
    setting.value if setting
  end

  def to_f
    value.to_f
  end

  def to_i
    value.to_i
  end

  def to_s
    value
  end

  def constant_name
    name.upcase.gsub(/[^A-Z0-9\s_-]+/,'').gsub(/[\s-]+/,'_')
  end

  def constant_value
    return value.to_i if Integer(value) rescue false
    return value.to_f if Float(value) rescue false
    return true if value == "true"
    return false if value == "false"
    return value
  end

  def self.is_configured?
    self.method_name_to_setting_value(:is_configured)
  end

  def self.pretty_site_name
    self.method_name_to_setting_value(:pretty_site_name)
  end


def self.is_configured
 self.method_name_to_setting_value(:is_configured)
end

def self.pretty_site_name
  self.method_name_to_setting_value(:pretty_site_name)
end

def self.site_name
  self.method_name_to_setting_value(:site_name)
end

def self.site_url
  self.method_name_to_setting_value(:site_url)
end

def self.notifier_email
  self.method_name_to_setting_value(:notifier_email)
end

def self.contact_email
  self.method_name_to_setting_value(:contact_email)
end

def self.records_per_page_choices
  self.method_name_to_setting_value(:records_per_page_choices)
end

def self.default_records_per_page
  self.method_name_to_setting_value(:default_records_per_page)
end

def self.default_search_class
  self.method_name_to_setting_value(:default_search_class)
end

def self.number_of_related_things_to_display_per_type
  self.method_name_to_setting_value(:number_of_related_things_to_display_per_type)
end

def self.number_of_related_images_to_display
  self.method_name_to_setting_value(:number_of_related_images_to_display)
end

def self. default_number_of_multiples
  self.method_name_to_setting_value(:default_number_of_multiples)
end

def self.flagging_tags
  self.method_name_to_setting_value(:flagging_tags)
end

def self.legacy_imagefile_paths_up_to
  self.method_name_to_setting_value(:legacy_imagefile_paths_up_to)
end

def self.legacy_audiorecording_paths_up_to
  self.method_name_to_setting_value(:legacy_audiorecording_paths_up_to)
end

def self.legacy_document_paths_up_to
  self.method_name_to_setting_value(:legacy_document_paths_up_to)
end

def self.legacy_video_paths_up_to
  self.method_name_to_setting_value(:legacy_video_paths_up_to)
end

def self.require_activation
  self.method_name_to_setting_value(:require_activation)
end

def self.about_basket
  self.method_name_to_setting_value(:about_basket)
end

def self.help_basket
  self.method_name_to_setting_value(:help_basket)
end

def self.extended_field_for_user_name
  self.method_name_to_setting_value(:extended_field_for_user_name)
end

def self.download_warning
  self.method_name_to_setting_value(:download_warning)
end

def self.tags_synonyms
  self.method_name_to_setting_value(:tags_synonyms)
end

def self.description_synonyms
  self.method_name_to_setting_value(:description_synonyms)
end

def self.description_template
  self.method_name_to_setting_value(:description_template)
end

def self.image_sizes
  self.method_name_to_setting_value(:image_sizes)
end

def self.image_content_types
  self.method_name_to_setting_value(:image_content_types)
end

def self.maximum_uploaded_file_size
  self.method_name_to_setting_value(:maximum_uploaded_file_size)
end

def self.document_content_types
  self.method_name_to_setting_value(:document_content_types)
end

def self.audio_content_types
  self.method_name_to_setting_value(:audio_content_types)
end

def self.video_content_types
  self.method_name_to_setting_value(:video_content_types)
end

def self.setup_sections
  self.method_name_to_setting_value(:setup_sections)
end

def self.documentation_basket
  self.method_name_to_setting_value(:documentation_basket)
end

def self.enable_converting_documents
  self.method_name_to_setting_value(:enable_converting_documents)
end

def self.default_policy_is_full_moderation
  self.method_name_to_setting_value(:default_policy_is_full_moderation)
end

def self.blank_title
  self.method_name_to_setting_value(:blank_title)
end

def self.pending_flag
  self.method_name_to_setting_value(:pending_flag)
end

def self.rejected_flag
  self.method_name_to_setting_value(:rejected_flag)
end

def self.blank_flag
  self.method_name_to_setting_value(:blank_flag)
end

def self.reviewed_flag
  self.method_name_to_setting_value(:reviewed_flag)
end

def self.frequency_of_moderation_email
  self.method_name_to_setting_value(:frequency_of_moderation_email)
end

def self.title_synonyms
  self.method_name_to_setting_value(:title_synonyms)
end

def self.short_summary_synonyms
  self.method_name_to_setting_value(:short_summary_synonyms)
end

def self.import_fields_to_ignore
  self.method_name_to_setting_value(:import_fields_to_ignore)
end

def self.default_baskets_ids
  self.method_name_to_setting_value(:default_baskets_ids)
end

def self.captcha_type
  self.method_name_to_setting_value(:captcha_type)
end

def self.default_content_license
  self.method_name_to_setting_value(:default_content_license)
end

def self.force_https_on_restricted_pages
  self.method_name_to_setting_value(:force_https_on_restricted_pages)
end

def self.no_public_version_title
  self.method_name_to_setting_value(:no_public_version_title)
end

def self.no_public_version_description
  self.method_name_to_setting_value(:no_public_version_description)
end

def self.provide_oai_pmh_repository
  self.method_name_to_setting_value(:provide_oai_pmh_repository)
end

def self.uses_basket_list_navigation_menu_on_every_page
  self.method_name_to_setting_value(:uses_basket_list_navigation_menu_on_every_page)
end

def self.available_syntax_highlighters
  self.method_name_to_setting_value(:available_syntax_highlighters)
end

def self.government_website
  self.method_name_to_setting_value(:government_website)
end

def self.default_page_keywords
  self.method_name_to_setting_value(:default_page_keywords)
end

def self.default_page_description
  self.method_name_to_setting_value(:default_page_description)
end

def self.enable_user_portraits
  self.method_name_to_setting_value(:enable_user_portraits)
end

def self.enable_gravatar_support
  self.method_name_to_setting_value(:enable_gravatar_support)
end

def self.basket_creation_policy
  self.method_name_to_setting_value(:basket_creation_policy)
end

def self.enable_embedded_support
  self.method_name_to_setting_value(:enable_embedded_support)
end

def self.image_slideshow_size
  self.method_name_to_setting_value(:image_slideshow_size)
end

def self.related_items_position_
default
  self.method_name_to_setting_value(:related_items_position_)
default
end

def self.hide_related_items_position_field
  self.method_name_to_setting_value(:hide_related_items_position_field)
end

def self.show_powered_by_kete
  self.method_name_to_setting_value(:show_powered_by_kete)
end

def self.additional_credits_html
  self.method_name_to_setting_value(:additional_credits_html)
end

def self.notify_site_admins_of_flaggings
  self.method_name_to_setting_value(:notify_site_admins_of_flaggings)
end

def self.keep_embedded_metadata_for_all_sizes
  self.method_name_to_setting_value(:keep_embedded_metadata_for_all_sizes)
end

def self.display_topic_type_on_search_result
  self.method_name_to_setting_value(:display_topic_type_on_search_result)
end

def self.display_related_topics_as_topic_type_counts
  self.method_name_to_setting_value(:display_related_topics_as_topic_type_counts)
end

def self.restricted_flag
  self.method_name_to_setting_value(:restricted_flag)
end

def self.add_date_created_to_item_search_record
  self.method_name_to_setting_value(:add_date_created_to_item_search_record)
end

def self.display_search_terms_field
  self.method_name_to_setting_value(:display_search_terms_field)
end

def self.display_date_range_fields
  self.method_name_to_setting_value(:display_date_range_fields)
end

def self.display_privacy_fields
  self.method_name_to_setting_value(:display_privacy_fields)
end

def self.default_search_privacy
  self.method_name_to_setting_value(:default_search_privacy)
end

def self.display_item_type_field
  self.method_name_to_setting_value(:display_item_type_field)
end

def self.display_topic_type_field
  self.method_name_to_setting_value(:display_topic_type_field)
end

def self.display_basket_field
  self.method_name_to_setting_value(:display_basket_field)
end

def self.display_sorting_fields
  self.method_name_to_setting_value(:display_sorting_fields)
end

def self.display_choices_field
  self.method_name_to_setting_value(:display_choices_field)
end

def self.language_choices_position
  self.method_name_to_setting_value(:language_choices_position)
end

def self.language_choices_display_type
  self.method_name_to_setting_value(:language_choices_display_type)
end

def self.search_selected_topic_type
  self.method_name_to_setting_value(:search_selected_topic_type)
end

def self.search_select_current_basket
  self.method_name_to_setting_value(:search_select_current_basket)
end

def self.dc_date_display_on_search_results
  self.method_name_to_setting_value(:dc_date_display_on_search_results)
end

def self.dc_date_display_detail_level
  self.method_name_to_setting_value(:dc_date_display_detail_level)
end

def self.dc_date_display_formulator
  self.method_name_to_setting_value(:dc_date_display_formulator)
end

def self.list_baskets_number
  self.method_name_to_setting_value(:list_baskets_number)
end

def self.contact_url
  self.method_name_to_setting_value(:contact_url)
end

def self.allowed_anonymous_actions
  self.method_name_to_setting_value(:allowed_anonymous_actions)
end

def self.enable_maps
  self.method_name_to_setting_value(:enable_maps)
end

def self.default_latitude
  self.method_name_to_setting_value(:default_latitude)
end

def self.default_longitude
  self.method_name_to_setting_value(:default_longitude)
end

def self.default_zoom_level
  self.method_name_to_setting_value(:default_zoom_level)
end

def self.use_backgroundrb_for_cache_expirations
  self.method_name_to_setting_value(:use_backgroundrb_for_cache_expirations)
end

def self.use_backgroundrb_for_search_record_updates
  self.method_name_to_setting_value(:use_backgroundrb_for_search_record_updates)
end

def self.administrator_activates
  self.method_name_to_setting_value(:administrator_activates)
end


private

  def self.method_name_to_setting_value(underscore_name)
    # SystemSetting.pretty_print -> SystemSetting.find_by_name("Pretty Print").value
    # SystemSetting.is_configured? -> SystemSetting.find_by_name("Is Configured").value

    underscore_name = underscore_name.to_s

    underscore_name =~ /^(.*?)\??$/
    setting_name = $1.titleize

    if setting = SystemSetting.find_by_name(setting_name)
      return setting.constant_value
    else
      raise NoMethodError.new("unknown method: SystemSetting.#{underscore_name}")
    end
  end
end


class SystemSetting::Defaults
  def is_configured
    false
  end

  # we have to load meaningless default values for any constant used in our models
  # since otherwise things like migrations will fail, before we bootstrap the db
  # these will be set up with system settings after rake db:bootstrap
  def maximum_uploaded_file_size
    50.megabyte 
  end

  def image_sizes 
    {:small_sq => '50x50!', :small => '50', :medium => '200>', :large => '400>'} 
  end

  def audio_content_types
    ['audio/mpeg']
  end

  def document_content_types
    ['text/html']
  end

  def enable_converting_documents
    false
  end

  def enable_embedded_support
    false
  end

  def image_content_types
    [:image]
  end

  def video_content_types
    ['video/mpeg']
  end

  def site_url
    "kete.net.nz"
  end

  def notifier_email
    "kete@library.org.nz"
  end

  def default_baskets_ids
    [1]
  end

  def no_public_version_title
    ""
  end

  def blank_title
    ""
  end
end


