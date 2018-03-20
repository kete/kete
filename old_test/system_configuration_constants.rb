# frozen_string_literal: true

SystemSetting.find(:all).each do |setting|
  set_constant(setting.constant_name.to_sym, setting.constant_value)
end

set_constant(:SystemSetting.is_configured?, true)
set_constant(:PRETTY_SITE_NAME, "Kete")
set_constant(:SITE_NAME, "www.example.com")
# set_constant(:SystemSetting.full_site_url, "http://www.example.com/") # webrat relies on www.example.com
set_constant(:NOTIFIER_EMAIL, "user@changeme.com")
set_constant(:CONTACT_EMAIL, "user@changeme.com")
set_constant(:MAXIMUM_UPLOADED_FILE_SIZE, 52428800)
set_constant(:CONTACT_URL, SystemSetting.full_site_url + "about/")

ZoomDb.zoom_id_stub = "oai:" + SITE_NAME + ":"
ZoomDb.zoom_id_element_name = "identifier"
# in case your zoom_id is in a nested element
# separated by /'s
# no preceding / necessary
ZoomDb.zoom_id_xml_path_up_to_element = "record/header"
