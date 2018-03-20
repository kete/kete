# frozen_string_literal: true
# !! Re-enable on switch to rails 3.2:
## Walter McGinnis, 2011-02-15
## because of load order, these can't be added to config/initializers
# if Rails.env == 'test'
#  OembedProvider.provider_name = "Example.com"
#  OembedProvider.provider_url = "http://example.com"
# else
#  OembedProvider.provider_name = Kete.respond_to?(:pretty_site_name) ? Kete.pretty_site_name : "Kete waiting configuration"
#  OembedProvider.provider_url = Kete.respond_to?(:site_name) && SystemSetting.site_name.present? ? SystemSetting.site_name : "http://placeholder_url"
# end
#
# OembedProvider.controller_model_maps = { 'images' => 'StillImage' }
