# has to do with use of attachment_fu
BASE_PRIVATE_PATH = 'private'

# these are commonly used across models / controllers / libs
# So we define them here so they are available in all those areas
# (needs to be run after load_system_settings.rb)
if Object.const_defined?(:BLANK_TITLE) && Object.const_defined?(:NO_PUBLIC_VERSION_TITLE)
  PUBLIC_CONDITIONS = "title != '#{BLANK_TITLE}' AND title != '#{NO_PUBLIC_VERSION_TITLE}'"
else
  PUBLIC_CONDITIONS = "title IS NOT NULL"
end
