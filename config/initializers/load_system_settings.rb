# if SystemSetting model doesn't exist, set IS_CONFIGURED to false
if Object.const_defined?('SystemSetting') and ActiveRecord::Base.connection.table_exists?('system_settings')
  # make each setting a global constant
  # as well as accessable as reader method from Kete application object
  #  (constants use to be eventually to be phased out in favor of Kete application object)
  # exceptions (will remain constants) are IS_CONFIGURED and SITE_URL
  # see reference for Module for more details about constant setting, etc.
  site_name_setting = SystemSetting.find_by_name('Site Name')
  SystemSetting.find(:all).each do |setting|
    if setting.name == 'Site URL' and setting.value.blank? and !site_name_setting.value.blank?
      SITE_URL = 'http://' + site_name_setting.value + '/'
      Kete.define_reader_method_as('site_url', SITE_URL)
    else
      setting.to_constant
      Kete.define_reader_method_for(setting)
    end
  end

  if !Object.const_defined?('IS_CONFIGURED')
    IS_CONFIGURED = false
  end
else
  IS_CONFIGURED = false
  Kete.define_reader_method_as('is_configured', IS_CONFIGURED)

  # we have to load meaningless default values for any constant used in our models
  # since otherwise things like migrations will fail, before we bootstrap the db
  # these will be set up with system settings after rake db:bootstrap
  MAXIMUM_UPLOADED_FILE_SIZE = 50.megabyte
  Kete.define_reader_method_as('maximum_uploaded_file_size', MAXIMUM_UPLOADED_FILE_SIZE)

  IMAGE_SIZES = {:small_sq => '50x50!', :small => '50', :medium => '200>', :large => '400>'}
  Kete.define_reader_method_as('image_sizes', IMAGE_SIZES)

  AUDIO_CONTENT_TYPES = ['audio/mpeg']
  Kete.define_reader_method_as('audio_content_types', AUDIO_CONTENT_TYPES)

  DOCUMENT_CONTENT_TYPES = ['text/html']
  Kete.define_reader_method_as('document_content_types', DOCUMENT_CONTENT_TYPES)

  ENABLE_CONVERTING_DOCUMENTS = false
  Kete.define_reader_method_as('enable_converting_documents', ENABLE_CONVERTING_DOCUMENTS)

  ENABLE_EMBEDDED_SUPPORT = false
  Kete.define_reader_method_as('enable_embedded_support', ENABLE_EMBEDDED_SUPPORT)

  IMAGE_CONTENT_TYPES = [:image]
  Kete.define_reader_method_as('image_content_types', IMAGE_CONTENT_TYPES)

  VIDEO_CONTENT_TYPES = ['video/mpeg']
  Kete.define_reader_method_as('video_content_types', VIDEO_CONTENT_TYPES)

  SITE_URL = "kete.net.nz"
  Kete.define_reader_method_as('site_url', SITE_URL)

  NOTIFIER_EMAIL = "kete@library.org.nz"
  Kete.define_reader_method_as('notifier_email', NOTIFIER_EMAIL)

  DEFAULT_BASKETS_IDS = [1]
  Kete.define_reader_method_as('default_baskets_ids', DEFAULT_BASKETS_IDS)

  NO_PUBLIC_VERSION_TITLE = String.new
  Kete.define_reader_method_as('no_public_version_title', NO_PUBLIC_VERSION_TITLE)

  BLANK_TITLE = String.new
  Kete.define_reader_method_as('blank_title', BLANK_TITLE)
end

