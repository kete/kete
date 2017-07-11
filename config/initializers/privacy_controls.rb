# has to do with use of attachment_fu
BASE_PRIVATE_PATH = 'private'

# these are commonly used across models / controllers / libs
# So we define them here so they are available in all those areas
# (needs to be run after load_system_settings.rb)
value = 'title IS NOT NULL'
if Object.const_defined?(:Kete) && Kete.respond_to?(:blank_title) && Kete.respond_to?(:no_public_version_title)
  value = "title != '#{SystemSetting.blank_title}' AND title != '#{SystemSetting.no_public_version_title}'"
  Kete.define_reader_method_as('public_conditions', value)
end

PUBLIC_CONDITIONS = value
