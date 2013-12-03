source "https://rubygems.org"

gem "rails", "3.2.15"

gem 'sass-rails'
# EOIN: TODO: I suspect there are gems mentioned in here that rails pulls in implicitly - we should remove them from here if so.
gem 'prototype-rails'
gem 'rails-erd'
gem 'haml'
gem 'acts_as_licensed', github: 'kete/acts_as_licensed', branch: 'rails3-gem'
# gem "sql-logging"


# RABID: the official version of acts_as_versioned seems to be abandoned but
# 		 this fork claims to have rails 3 support
gem 'acts_as_versioned', github: "jwhitehorn/acts_as_versioned"

# RABID: the old plugin version of acts-as-taggable-on was 1.0.0
gem "acts-as-taggable-on", "~> 2.4.1"

# # Somebody else upgraded attachment_fu for rails 3 so we didn't have to :-)
gem 'pothoven-attachment_fu'
# gem 'pothoven-attachment_fu', path: '/Users/eoinkelly/Code/kete-gems/po_attachment_fu'

# EOIN: 
# * kete had it's own feedzirra but it appears to differ in name only. There
#   may have been a plan to diverge it but it doesn't seem to have happened - see
#   https://github.com/kete/feedzirra/commits/master
# * for this reason, we are now using the main feedzirra gem
gem 'feedzirra', '~> 0.4.0'
# gem 'kete-feedzirra', github: 'kete/feedzirra'

# https://github.com/swanandp/acts_as_list
gem 'acts_as_list', '~> 0.3.0'

gem 'acts_as_configurable', '0.0.8'

# EOIN: piggy_back is an old implementation of AR #include e.g User.include(:roles).find.where(...) etc.
#gem "piggy_back", "#.#.#", :git => "git://github.com/shuber/sortable.git" # 2009-03-17

gem 'routing-filter', '~> 0.3.1'

#gem 'oembed_provider_engine' # !! re-enable on Rails 3.2

# gem "mysql"
gem 'pg'

gem 'railroady'
gem "awesome_nested_set", "~> 2.1.6"
# Added to get rake working. I suspect these should be removed.
# gem 'rake', '0.9.2.2' # version needed to use: require 'rake/rdoctask'
gem "rake", "~> 10.1.0"
gem "rdoc"
gem 'nokogiri', '~> 1.6.0'

# Background tasks
# ################
gem "backgroundrb-rails3", "~> 1.1.6", :require => 'backgroundrb'

gem 'mini_exiftool', '< 2.0.0'

## You'll need Zebra and Yaz installed (Z39.50 databse and ZOOM API).
#gem 'zoom'
##gem 'acts_as_zoom' # included in gem/plugins 


gem 'rmagick', "2.12.2", :require => 'RMagick'

group :development, :test do
  gem "sqlite3", "~> 1.3.7"
  gem "rspec-rails", "~> 2.14.0"
  gem "factory_girl_rails", "~> 4.3.0"
  gem "pry-rails"
  
  gem "debugger", :platforms => [:mingw_19, :ruby_19]
  gem 'debugger-xml', :platforms => [:mingw_19, :ruby_19]

  gem 'byebug', :platforms => [:mingw_20, :ruby_20]
  gem 'pry-byebug', :platforms => [:mingw_20, :ruby_20]

  gem 'awesome_print'


#  gem 'webrat'
#  gem 'shoulda', "2.0.0" # !! ruby 1.8.7 requirement
#  gem 'factory_girl', "1.2.4"
#  gem "rspec-rails", "~> 2.13.0"
#  # gem "shoulda", "~> 3.4.0"
#  gem "capybara", "~> 2.0.2"
#  gem "poltergeist", "~> 1.1.0"
#  gem "debugger", "~> 1.4.0"
#  gem "factory_girl_rails", "~> 4.2.1"
end


# Note: the file config/required_software.yml is a good place to look for things that would be needed in a bundler file.

gem 'oai', '~> 0.3.1'

gem 'packet'
gem 'RedCloth'
gem 'hpricot'

##gem 'tiny_mce'
gem 'avatar'
#gem 'zoom'
gem 'chronic'
gem 'ya2yaml'
gem 'libxml-ruby'
gem 'gmaps4rails', '1.4.2'

gem 'unicode'
gem 'xml-simple'
#gem 'system_timer'
gem 'mime-types'
#gem 'tiny_mce_plugin_imageselector', '>= 0.0.7'
gem 'htmlentities'

gem 'http_url_validation_improved'

# $ rake manage_gems:required:install:
# 
# "gem install --no-rdoc --no-ri nokogiri"
# ERROR:  Error installing nokogiri:
# 	nokogiri requires Ruby version >= 1.9.2.
# "gem install --no-rdoc --no-ri tiny_mce"
# "gem install --no-rdoc --no-ri avatar"
## "gem install --no-rdoc --no-ri zoom"
# "gem install --no-rdoc --no-ri chronic"
# "gem install --no-rdoc --no-ri ya2yaml"
# "gem install --no-rdoc --no-ri libxml-ruby"
# "gem install --no-rdoc --no-ri oembed_provider"
# ERROR:  Error installing oembed_provider:
# 	oembed_provider requires addressable (>= 0)
# "gem install --no-rdoc --no-ri gmaps4rails --version='1.4.2'"
# "gem install --no-rdoc --no-ri unicode"
# "gem install --no-rdoc --no-ri xml-simple"
# "gem install --no-rdoc --no-ri system_timer"
# "gem install --no-rdoc --no-ri mime-types"
# "gem install --no-rdoc --no-ri tiny_mce_plugin_imageselector --version='>= 0.0.7'"
# "gem install --no-rdoc --no-ri kete-feedzirra"
# ERROR:  Error installing kete-feedzirra:
# 	nokogiri requires Ruby version >= 1.9.2.
# "gem install --no-rdoc --no-ri htmlentities"
# "gem install --no-rdoc --no-ri packet --version='>= 0.1.14'"
# {15:27}[1.8.7@Kete]~dir:master ✗ ➭


# Gems originally found in vendor/plugins. Can have versions updated
# (I've locked versions to avoid errors during upgrade).


gem 'active_scaffold',              '~> 3.3.3'
gem "acts_as_authenticated", "2.0", :git => "git://github.com/gundestrup/acts_as_authenticated.git" # 2007-06-06
#gem "acts_as_licensed", "#.#.#", :git => "git://github.com/shuber/sortable.git" # 2008-07-10
gem "acts_as_soft_deletable", :git => "git://github.com/says/acts_as_soft_deletable.git" # 2009-02-16
## gem 'acts_as_zoom'
gem 'authorization',                '1.0.11' # >> 2008-10-01
#gem 'auto_complete',                '0.0.1' # >> 2008-10-23
#gem 'backgroundrb-rails3',          '1.1.0' # >> 2008-10-15, replaces 'backgroundrb'
#gem 'better_nested_set',            '0.1.1' # >> 2008-08-04    
#gem "brain_buster", "#.#.#", :git => "git://github.com/shuber/sortable.git" # 2009-05-25
#gem "bundle-fu", "#.#.#", :git => "git://github.com/shuber/sortable.git" # 2009-02-16
#gem "convert_attachment_to", "#.#.#", :git => "git://github.com/shuber/sortable.git" # 2008-07-10
#gem "external_search_sources", "#.#.#", :git => "git://github.com/shuber/sortable.git" # 2010-01-06
#gem 'foreign_key_migrations',       '0.3.0' # ~= 2008-06-30
#gem 'mimetype-fu',                  '0.1.1' # >> 2008-07-17
#gem "random_finders", "#.#.#", :git => "git://github.com/shuber/sortable.git" # 2007-12-07
#gem 'redbox',                       '1.0.3' # >> 2007-12-21
#gem 'redhillonrails_core',          '1.0.4' # >> 2008-06-30
#gem 'ssl_requirement',              '0.0.1' # >> 2008-05-29
#gem 'nove-system-settings',         '0.2.0' # >> 2008-01-14, replaces 'system_settings'
gem 'will_paginate', '~> 3.0.5'


# RABID: should be removed:
gem 'validates_xml',                '1.0.3' # >> 2007-06-06 
