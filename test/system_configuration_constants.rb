SystemSetting.find(:all).each do |setting|
  set_constant(setting.constant_name.to_sym, setting.constant_value)
end

set_constant(:IS_CONFIGURED, true)
set_constant(:PRETTY_SITE_NAME, "Kete")
set_constant(:SITE_NAME, "www.example.com")
set_constant(:SITE_URL, "http://www.example.com/") # webrat relies on www.example.com
set_constant(:NOTIFIER_EMAIL, "user@changeme.com")
set_constant(:CONTACT_EMAIL, "user@changeme.com")
set_constant(:MAXIMUM_UPLOADED_FILE_SIZE, 52428800)
set_constant(:CONTACT_URL, SITE_URL + "about/")

