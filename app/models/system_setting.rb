class SystemSetting

  # EOIN:
  # This class manages system settings in Kete. Currently it is a bit of a mess
  # internally but we don't care as long as it provides a nice clean external
  # interface for the rest of the app to use. 
  
  def self.admin_email
    self.setting(:admin_email)
  end

  def self.is_configured?
    self.setting(:is_configured)
  end

  def self.pretty_site_name
    self.setting(:pretty_site_name)
  end

  def self.is_configured
   self.setting(:is_configured)
  end

  def self.pretty_site_name
    self.setting(:pretty_site_name)
  end

  def self.site_name
    self.setting(:site_name)
  end

  def self.full_site_url
    "http:/#{self.setting(:site_url)}/"
  end

  def self.site_url
    self.setting(:site_url)
  end

  def self.notifier_email
    self.setting(:notifier_email)
  end

  def self.contact_email
    self.setting(:contact_email)
  end

  def self.records_per_page_choices
    self.setting(:records_per_page_choices)
  end

  def self.default_records_per_page
   self.setting(:default_records_per_page)
  end

  def self.default_search_class
   self.setting(:default_search_class)
  end

  def self.number_of_related_things_to_display_per_type
   self.setting(:number_of_related_things_to_display_per_type)
  end

  def self.number_of_related_images_to_display
   self.setting(:number_of_related_images_to_display)
  end

  #def self.default_number_of_multiples
  #  self.setting(:default_number_of_multiples)
  #end

  #def self.flagging_tags
  #  self.setting(:flagging_tags)
  #end
  #
  #def self.legacy_imagefile_paths_up_to
  #  self.setting(:legacy_imagefile_paths_up_to)
  #end
  #
  #def self.legacy_audiorecording_paths_up_to
  #  self.setting(:legacy_audiorecording_paths_up_to)
  #end
  #
  #def self.legacy_document_paths_up_to
  #  self.setting(:legacy_document_paths_up_to)
  #end
  #
  #def self.legacy_video_paths_up_to
  #  self.setting(:legacy_video_paths_up_to)
  #end

  def self.require_activation?
    self.setting(:require_activation)
  end

  def self.about_basket
    self.setting(:about_basket)
  end

  #def self.help_basket
  #  self.setting(:help_basket)
  #end
  #
  #def self.extended_field_for_user_name
  #  self.setting(:extended_field_for_user_name)
  #end

  def self.download_warning
    self.setting(:download_warning)
  end

  #def self.tags_synonyms
  #  self.setting(:tags_synonyms)
  #end

  #def self.description_synonyms
  #  self.setting(:description_synonyms)
  #end
  #
  #def self.description_template
  #  self.setting(:description_template)
  #end

  def self.image_sizes
    self.setting(:image_sizes)
  end

  def self.image_content_types
   self.setting(:image_content_types)
  end
  #
  def self.maximum_uploaded_file_size
    self.setting(:maximum_uploaded_file_size)
  end
  
  def self.document_content_types
   self.setting(:document_content_types)
  end
  
  def self.audio_content_types
   self.setting(:audio_content_types)
  end
  
  def self.video_content_types
   self.setting(:video_content_types)
  end
  #
  #def self.setup_sections
  #  self.setting(:setup_sections)
  #end
  
  #def self.documentation_basket
  #  self.setting(:documentation_basket)
  #end
  
  def self.enable_converting_documents
   self.setting(:enable_converting_documents)
  end
  
  #def self.default_policy_is_full_moderation
  #  self.setting(:default_policy_is_full_moderation)
  #end

  def self.blank_title
    self.setting(:blank_title)
  end

  def self.pending_flag
    self.setting(:pending_flag)
  end

  def self.rejected_flag
    self.setting(:rejected_flag)
  end

  def self.blank_flag
    self.setting(:blank_flag)
  end

  def self.reviewed_flag
    self.setting(:reviewed_flag)
  end

  def self.frequency_of_moderation_email
    self.setting(:frequency_of_moderation_email)
  end

  #def self.title_synonyms
  #  self.setting(:title_synonyms)
  #end

  #def self.short_summary_synonyms
  #  self.setting(:short_summary_synonyms)
  #end

  #def self.import_fields_to_ignore
  #  self.setting(:import_fields_to_ignore)
  #end

  #def self.default_baskets_ids
  #  self.setting(:default_baskets_ids)
  #end

  def self.captcha_type
    self.setting(:captcha_type)
  end

  #def self.default_content_license
  #  self.setting(:default_content_license)
  #end

  def self.force_https_on_restricted_pages
    self.setting(:force_https_on_restricted_pages)
  end

  def self.no_public_version_title
    self.setting(:no_public_version_title)
  end

  def self.no_public_version_description
    self.setting(:no_public_version_description)
  end

  def self.provide_oai_pmh_repository
    self.setting(:provide_oai_pmh_repository)
  end

  #def self.uses_basket_list_navigation_menu_on_every_page
  #  self.setting(:uses_basket_list_navigation_menu_on_every_page)
  #end

  #def self.available_syntax_highlighters
  #  self.setting(:available_syntax_highlighters)
  #end

  def self.government_website
    self.setting(:government_website)
  end

  def self.default_page_keywords
   self.setting(:default_page_keywords)
  end

  def self.default_page_description
    self.setting(:default_page_description)
  end

  #def self.enable_user_portraits
  #  self.setting(:enable_user_portraits)
  #end

  #def self.enable_gravatar_support
  #  self.setting(:enable_gravatar_support)
  #end

  #def self.basket_creation_policy
  #  self.setting(:basket_creation_policy)
  #end

  def self.enable_embedded_support
   self.setting(:enable_embedded_support)
  end

  def self.image_slideshow_size
   self.setting(:image_slideshow_size)
  end

  def self.related_items_position_default
    self.setting(:related_items_position_default)
  end

  def self.hide_related_items_position_field
    self.setting(:hide_related_items_position_field)
  end

  def self.show_powered_by_kete?
    self.setting(:show_powered_by_kete)
  end

  def self.additional_credits_html
    self.setting(:additional_credits_html)
  end

  #def self.notify_site_admins_of_flaggings
  #  self.setting(:notify_site_admins_of_flaggings)
  #end

  def self.keep_embedded_metadata_for_all_sizes
   self.setting(:keep_embedded_metadata_for_all_sizes)
  end

  #def self.display_topic_type_on_search_result
  #  self.setting(:display_topic_type_on_search_result)
  #end

  #def self.display_related_topics_as_topic_type_counts
  #  self.setting(:display_related_topics_as_topic_type_counts)
  #end

  def self.restricted_flag
    self.setting(:restricted_flag)
  end

  def self.add_date_created_to_item_search_record
    self.setting(:add_date_created_to_item_search_record)
  end

  def self.display_search_terms_field
   self.setting(:display_search_terms_field)
  end

  def self.display_date_range_fields
   self.setting(:display_date_range_fields)
  end

  def self.display_privacy_fields
   self.setting(:display_privacy_fields)
  end

  #def self.default_search_privacy
  #  self.setting(:default_search_privacy)
  #end

  def self.display_item_type_field
   self.setting(:display_item_type_field)
  end

  def self.display_topic_type_field
   self.setting(:display_topic_type_field)
  end

  def self.display_basket_field
   self.setting(:display_basket_field)
  end

  def self.display_sorting_fields
   self.setting(:display_sorting_fields)
  end

  def self.display_choices_field
   self.setting(:display_choices_field)
  end

  #def self.language_choices_position
  #  self.setting(:language_choices_position)
  #end

  #def self.language_choices_display_type
  #  self.setting(:language_choices_display_type)
  #end

  def self.search_selected_topic_type
   self.setting(:search_selected_topic_type)
  end

  def self.search_select_current_basket
   self.setting(:search_select_current_basket)
  end

  def self.dc_date_display_on_search_results?
    self.setting(:dc_date_display_on_search_results?)
  end

  def self.dc_date_display_detail_level
    self.setting(:dc_date_display_detail_level)
  end

  def self.dc_date_display_formulator
    self.setting(:dc_date_display_formulator)
  end

  def self.list_baskets_number
   self.setting(:list_baskets_number)
  end

  def self.contact_url
   self.setting(:contact_url)
  end

  def self.allowed_anonymous_actions
    self.setting(:allowed_anonymous_actions)
  end

  def self.enable_maps?
    self.setting(:enable_maps)
  end

  def self.default_latitude
    self.setting(:default_latitude)
  end

  def self.default_longitude
    self.setting(:default_longitude)
  end

  def self.default_zoom_level
    self.setting(:default_zoom_level)
  end

  def self.use_backgroundrb_for_cache_expirations
    self.setting(:use_backgroundrb_for_cache_expirations)
  end

  def self.use_backgroundrb_for_search_record_updates
    self.setting(:use_backgroundrb_for_search_record_updates)
  end

  def self.administrator_activates?
    self.setting(:administrator_activates)
  end

  def self.uses_basket_list_navigation_menu_on_every_page?
    self.setting(:uses_basket_list_navigation_menu_on_every_page)
  end

  def self.enable_user_portraits?
    self.setting(:enable_user_portraits)
  end

  def self.enable_gravatar_support?
    self.setting(:enable_gravatar_support)
  end

  def self.language_choices_position
    self.setting(:language_choices_position)
  end

  def self.available_syntax_highlighters
    self.setting(:available_syntax_highlighters)
  end

private

  def self.setting(setting)
    # EOIN: 
    # we are unsure what the final use-case of these system settings will be so
    # we feel it is too early to do persistance for them. When it becomes
    # clearer, we can (if required) add the ability to load settings from
    # YAML/DB/whatever. 
    Defaults.new.send setting
  end

  class Defaults

    def default_page_keywords
      ""
    end

    def default_page_description
      ""
    end

    def uses_basket_list_navigation_menu_on_every_page
     false 
    end

    def enable_user_portraits
      false
    end

    def language_choices_position
      'header'
    end

    def enable_maps
      false
    end

    def display_search_terms_field
      false
    end

    def display_date_range_fields
      false
    end

    def display_privacy_fields
      false
    end

    def display_item_type_field
      false
    end

    def display_topic_type_field
      false
    end

    def display_basket_field
      false
    end

    def display_sorting_fields
      false
    end

    def display_choices_field
      false
    end
      
    def search_select_current_basket
      false
    end

    def list_baskets_number
      5 # EOIN: picked at random
    end

    def enable_gravatar_support
      false
    end

    def contact_url
      "mailto:eoin@rabidtech.co.nz"
    end

    def default_search_class
      "" 
    end

    def site_name
      "localhost"
    end

    def method_missing(meth, *args, &block)
      # catch any forgotten defaults with a better error message
      raise "You probably asked for a default setting that does not exist. You need to add the #{meth} to Defaults"
    end

    def allowed_anonymous_actions
      ""
    end

    def admin_email
      "foo@example.com"
    end

    def pretty_site_name
      "A working Kete"
    end

    def is_configured
      true 
    end

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
      "no public version"
    end

    def blank_title
      "blank title"
    end

    def available_syntax_highlighters
      []
    end

    def keep_embedded_metadata_for_all_sizes
      true
    end

    def provide_oai_pmh_repository
      true
    end

    def government_website
      "http://the.gov.is.watching"
    end

    def show_powered_by_kete
      false
    end

    def additional_credits_html
      ""
    end

    def pending_flag
      "pending"
    end

    def image_slideshow_size
      400 # seems to be a width in pixels
    end

    def captcha_type
      "all"
    end

    def number_of_related_images_to_display
      0
    end

    def number_of_related_things_to_display_per_type
      0
    end

    def default_records_per_page
      5 
    end

    def self.administrator_activates
      false
    end

    def self.require_activation
      false
    end

    def records_per_page_choices
      []
    end

    def dc_date_display_on_search_results?
      false
    end

    def search_selected_topic_type
      ""
    end
  end 
end


