# @todo change rubygems to https when cert fixed on appserver
source 'http://rubygems.org'

gem "rails", "2.3.5"
gem 'rake', '0.8.7'

gem "passenger"
gem "mysql", "2.8.1"
gem "rmagick", "2.12.2", :require => false
gem "mini_exiftool"

gem "nokogiri"
gem "packet",'>= 0.1.14'
gem "chronic"
gem "hpricot"
gem "unicode"
gem "RedCloth"
gem "mime-types"
gem "memcache-client"
gem "zoom"
gem "libxml-ruby"
gem "avatar"
gem "htmlentities"
gem "xml-simple"
gem "kete-feedzirra"
gem "tiny_mce"
gem "tiny_mce_plugin_imageselector", '>= 0.0.7'
gem "http_url_validation_improved"

# Walter McGinnis, 2011-02-15
# because this is a Rails engine gem
# it needs to be declared here as well as config/required_software.rb
gem "oembed_provider"
gem "ya2yaml"
gem "gmaps4rails",'1.4.2'

# Walter McGinnis, 2008-07-02
# we currently use a hacked version of oai gem
# and place it under vendor/gems
# specifying it here allows this to work
gem "oai", :path => 'vendor/gems/oai-0.0.12'


group :development do
  # after 2.9.0 we start having problems with capistrano-configuration
  gem 'capistrano', '2.9.0', :require => false
  gem 'capistrano-ext', :require => false
  gem 'capistrano-configuration', :require => false
  gem 'piston'
end

group :test do
  gem "shoulda", '2.11.3'
  gem 'factory_girl', '1.2.3'
  gem 'webrat', '0.7.3'
end
