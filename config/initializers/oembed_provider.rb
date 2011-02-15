# Walter McGinnis, 2011-02-15
# because of load order, these can't be added to config/initializers
OembedProvider.provider_name = Kete.pretty_site_name
if Rails.env == 'test'
  OembedProvider.provider_url = "http://example.com"
else
  OembedProvider.provider_url = Kete.site_url
end

