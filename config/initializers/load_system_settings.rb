# !! This entire file should be converted to using SystemSettings.something rather 
#    than Kete.something, (no meta-defining methods).
#    After this most of kete.rb can be removed.

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
end

