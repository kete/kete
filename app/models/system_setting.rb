
class SystemSetting
  module Defaults
    # RABID:
    #
    # Defaults, mostly taken from the system_setting table on an existing
    # Kete2 system's database.
    #
    # we are unsure what the final use-case of these system settings will be so
    # we feel it is too early to do persistance for them. When it becomes
    # clearer, we can (if required) add the ability to load settings from
    # YAML/DB/whatever.

    def contact_email
      'kete@library.org.nz'
    end

    # def default_number_of_multiples
    #  5
    # end

    def flagging_tags
      ['inaccurate', 'duplicate', 'inappropriate', 'entered by mistake', 'has typos']
    end

    def about_basket
      3
    end

    # def help_basket
    #  2
    # end
    #
    # def extended_field_for_user_name
    #  "user_name"
    # end

    # def tags_synonyms
    #  nil
    # end

    # def description_synonyms
    #  nil
    # end
    #
    # def description_template
    #  nil
    # end

    # def setup_sections
    #  ['Server', 'System', 'Accounts', 'Warnings', 'Flagging', 'Results Display', 'Related Items Display', 'Extended Fields']
    # end

    # def documentation_basket
    #  4
    # end

    def default_policy_is_full_moderation
      false
    end

    def rejected_flag
      'rejected'
    end

    def blank_flag
      'used for moderation'
    end

    def reviewed_flag
      'reviewed by moderator'
    end

    def frequency_of_moderation_email
      4
    end

    # def title_synonyms
    #  nil
    # end

    # def short_summary_synonyms
    #  nil
    # end

    # def import_fields_to_ignore
    #  ['HiliteLibrary']
    # end

    # def default_baskets_ids
    #  # ROB: not in the Kete2 system's system_settings database.
    # end

    def default_content_license
      License.find(1)
    end

    def force_https_on_restricted_pages
      false
    end

    def no_public_version_description
      'There is currently no public version of this item.'
    end

    # def uses_basket_list_navigation_menu_on_every_page
    #  false
    # end

    def basket_creation_policy
     'closed'
    end

    def related_items_position_default
      # ROB: In the exisiting data this is often saved as the empty string. 
      #      Some models also have "inset" or "sidebar"
      'below'
    end

    def hide_related_items_position_field
      true
    end

    # def notify_site_admins_of_flaggings
    #  false
    # end

    # def display_topic_type_on_search_result
    #  false
    # end

    # def display_related_topics_as_topic_type_counts
    #  false
    # end

    def restricted_flag
      'restricted'
    end

    def add_date_created_to_item_search_record
      true
    end

    def default_search_privacy
     'public'
    end

    # def language_choices_display_type
    #  "dropdown"
    # end

    def dc_date_display_detail_level
      'year_month_and_day'
    end

    def dc_date_display_formulator
      nil
    end

    def default_latitude
      -41.3368981
    end

    def default_longitude
      174.7725319
    end

    def default_zoom_level
      5
    end

    def use_backgroundrb_for_cache_expirations
      false
    end

    def use_backgroundrb_for_search_record_updates
      false
    end

    def default_page_keywords
      ''
    end

    def default_page_description
      ''
    end

    def uses_basket_list_navigation_menu_on_every_page
     false
    end

    def enable_user_portraits
      true
    end

    def language_choices_position
      'header'
    end

    def enable_maps
      false
    end

    def display_search_terms_field
      'menu'
    end

    def display_date_range_fields
      'menu'
    end

    def display_privacy_fields
      'menu'
    end

    def display_item_type_field
      'menu'
    end

    def display_topic_type_field
      false
    end

    def display_basket_field
      'menu'
    end

    # def display_sorting_fields
    #   "menu"
    # end

    def display_choices_field
      'menu'
    end

    def search_select_current_basket
      false
    end

    def list_baskets_number
      5 # EOIN: picked at random
    end

    def enable_gravatar_support
      true
    end

    def contact_url
      'mailto:kete@library.org.nz'
    end

    def default_search_class
      ''
    end

    def site_name
      'a-working-kete'
    end

    def method_missing(meth, *args, &block)
      # catch any forgotten defaults with a better error message
      raise "You probably asked for a default setting that does not exist. You need to add the #{meth} to Defaults"
    end

    def allowed_anonymous_actions
      ''
    end

    def admin_email
      'kete@library.org.nz'
    end

    def pretty_site_name
      'Kete Horowhenua'
    end

    def is_configured
      true
    end

    def maximum_uploaded_file_size
      50.megabyte
    end

    def image_sizes
      { small_sq: '50x50!', small: '50', medium: '200>', large: '400>' }
    end

    def audio_content_types
      ['audio/mpeg', 'audio/mpg', 'audio/mp3', 'audio/x-mpeg', 'audio/x-mpegurl', 'audio/wav', 'audio/x-wav', 'audio/x-ms-wma', 'audio/x-ms-waxaudio', 'audio/ogg', 'application/ogg', 'audio/x-vorbis+ogg', 'audio/x-aiff', 'application/octet-stream', 'audio/vorbis', 'audio/speex', 'audio/flac']
    end

    def document_content_types
      ['text/html', 'text/plain', 'text/rtf', 'text/css', 'application/mac-binhex40', 'application/msword', 'application/word', 'application/pdf', 'application/pics-rules', 'application/postscript', 'application/rtf', 'application/vnd.ms-excel', 'application/vnd.ms-powerpoint', 'application/x-gtar', 'application/x-gzip', 'application/zip', 'application/x-zip', 'application/x-zip-compressed', 'application/x-tar', 'application/x-compressed-tar', 'application/vnd.oasis.opendocument.chart', 'application/vnd.oasis.opendocument.database', 'application/vnd.oasis.opendocument.formula', 'application/vnd.oasis.opendocument.drawing', 'application/vnd.oasis.opendocument.image', 'application/vnd.oasis.opendocument.text-master', 'application/vnd.oasis.opendocument.presentation', 'application/vnd.oasis.opendocument.spreadsheet', 'application/vnd.oasis.opendocument.text', 'application/vnd.oasis.opendocument.text-web', 'image/jpeg', 'image/jpg', 'application/octet-stream', 'application/excel', 'application/x-excel', 'application/x-msexcel', 'application/msexcel', 'application/x-ms-excel', 'application/ms-excel', 'application/x-dos_ms_excel', 'image/vnd.adobe.photoshop', 'image/x-photoshop', 'application/x-photoshop', 'image/xcf', 'application/xml']
    end

    def enable_converting_documents
      false
    end

    def enable_embedded_support
      false
    end

    def image_content_types
      ['image/tiff', 'image/bmp', 'image/x-ms-bmp', 'image/quicktime', 'image/x-quicktime', 'application/postscript', 'application/octet-stream', 'image/vnd.adobe.photoshop', 'image/x-photoshop', 'image/vnd.adobe.photoshop', 'image/x-photoshop', 'application/x-photoshop', 'image/xcf', :image]
    end

    def video_content_types
      ['application/x-shockwave-flash', 'application/flash-video', 'application/x-flash-video', 'video/x-flv', 'video/mp4', 'video/x-m4v', 'video/mpeg', 'video/quicktime', 'video/x-msvideo', 'video/avi', 'video/x-quicktime', 'application/x-director', 'image/mov', 'application/asx', 'video/x-ms-asf-plugin', 'application/x-mplayer2', 'video/x-ms-asf', 'video/x-ms-wm', 'video/x-ms-wmv', 'video/x-ms-wvx', 'application/x-dvi', 'application/octet-stream', 'application/ogg', 'video/ogg', 'video/theora']
    end

    def site_url
      'horowhenua.kete.net.nz/'
    end

    def site_domain
      'horowhenua.kete.net.nz'
    end

    def notifier_email
      'kete@library.org.nz'
    end

    def default_baskets_ids
      [1]
    end

    # ROB: this is actually a new one I've added.
    def default_basket
      'site'
    end

    def no_public_version_title
      'no public version'
    end

    def blank_title
      'Pending Moderation'
    end

    def available_syntax_highlighters
      []
    end

    def keep_embedded_metadata_for_all_sizes
      true
    end

    def provide_oai_pmh_repository
      false
    end

    def government_website
      # This appears to be an array used to generate a link (see layouts/.application.html.haml).
      # Being blank seems to indicate this isn't a government website.
      []
    end

    def show_powered_by_kete
      true
    end

    def additional_credits_html
      ''
    end

    def pending_flag
      'pending'
    end

    def image_slideshow_size
      400 # seems to be a width in pixels
    end

    def captcha_type
      'question'
    end

    def number_of_related_images_to_display
      5
    end

    def number_of_related_things_to_display_per_type
      0
    end

    def default_records_per_page
      5
    end

    def administrator_activates
      false
    end

    def require_activation
      false
    end

    def records_per_page_choices
      []
    end

    def dc_date_display_on_search_results
      false
    end

    def search_selected_topic_type
      ''
    end

    def force_https_on_restricted_pages
      false
    end

    def download_warning
      'You are about to download a file from Kete. Kete is an open digital repository'+
      'and as such we can not guarantee the integrity of any file in the repository.  '+
      'Please ensure that your virus scan software is operating and is configured to '+
      "scan this download.\n"+
      'Are you sure you want to proceed?'
    end
  end
end

class SystemSetting
  # EOIN:
  # This class manages system settings in Kete. Currently it is a bit of a mess
  # internally but we don't care as long as it provides a nice clean external
  # interface for the rest of the app to use.

  extend SystemSetting::Defaults

  class << self
    alias_method :is_configured?, :is_configured
    alias_method :require_activation?, :require_activation
    alias_method :show_powered_by_kete?, :show_powered_by_kete
    alias_method :dc_date_display_on_search_results?, :dc_date_display_on_search_results
    alias_method :enable_maps?, :enable_maps
    alias_method :administrator_activates?, :administrator_activates
    alias_method :uses_basket_list_navigation_menu_on_every_page?, :uses_basket_list_navigation_menu_on_every_page
    alias_method :enable_user_portraits?, :enable_user_portraits
    alias_method :enable_gravatar_support?, :enable_gravatar_support
    alias_method :add_date_created_to_item_search_record?, :add_date_created_to_item_search_record
  end

  def self.uses_basket_list_navigation_menu_on_every_page?
    uses_basket_list_navigation_menu_on_every_page
  end

  def self.full_site_url
    "http://#{site_url}"
  end
end
