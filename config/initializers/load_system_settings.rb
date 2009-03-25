# if SystemSetting model doesn't exist, set IS_CONFIGURED to false
if Object.const_defined?('SystemSetting') and ActiveRecord::Base.connection.table_exists?('system_settings')
  # make each setting a global constant
  # see reference for Module for more details about constant setting, etc.
  site_name_setting = SystemSetting.find_by_name('Site Name')
  SystemSetting.find(:all).each do |setting|
    if setting.name == 'Site URL' and setting.value.blank? and !site_name_setting.value.blank?
      SITE_URL = 'http://' + site_name_setting.value + '/'
    else
      setting.to_constant
    end
  end

  if !Object.const_defined?('IS_CONFIGURED')
    IS_CONFIGURED = false
  end
else
  IS_CONFIGURED = false

  # we have to load meaningless default values for any constant used in our models
  # since otherwise things like migrations will fail, before we bootstrap the db
  # these will be set up with system settings after rake db:bootstrap
  MAXIMUM_UPLOADED_FILE_SIZE = 50.megabyte
  IMAGE_SIZES = {:small_sq => '50x50!', :small => '50', :medium => '200>', :large => '400>'}
  AUDIO_CONTENT_TYPES = ['audio/mpeg']
  DOCUMENT_CONTENT_TYPES = ['text/html']
  ENABLE_CONVERTING_DOCUMENTS = false
  ENABLE_EMBEDDED_SUPPORT = false
  IMAGE_CONTENT_TYPES = [:image]
  VIDEO_CONTENT_TYPES = ['video/mpeg']
  SITE_URL = "kete.net.nz"
  NOTIFIER_EMAIL = "kete@library.org.nz"
  DEFAULT_BASKETS_IDS = [1]
  NO_PUBLIC_VERSION_TITLE = String.new
  BLANK_TITLE = String.new
end

# Walter McGinnis (walter@katipo.co.nz), 2006-09-26
# include Globalize # put that thing here
# Locale.set_base_language('en-NZ') # and here :)'')

if IS_CONFIGURED
  # Walter McGinnis (walter@katipo.co.nz), 2006-12-06
  # used by the acts_as_zoom plugin
  ZoomDb.zoom_id_stub = "oai:" + SITE_NAME + ":"
  ZoomDb.zoom_id_element_name = "identifier"
  # in case your zoom_id is in a nested element
  # separated by /'s
  # no preceding / necessary
  ZoomDb.zoom_id_xml_path_up_to_element = "record/header"
end
