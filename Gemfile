# frozen_string_literal: true

source 'https://rubygems.org'

ruby '2.3.3'

gem 'rails', '3.2.22.5'
gem 'unicorn'

gem 'tinymce-rails', '~> 4.1.4'

# EOIN: TODO: I suspect there are gems mentioned in here that rails pulls in
# implicitly - we should remove them from here if so.

# Heroku needs this
gem 'rails_12factor', group: :production

gem 'acts_as_licensed', git: 'https://github.com/kete/acts_as_licensed.git', branch: 'rails3-gem'
gem 'haml'
gem 'jquery-rails', '~> 3.1.1'
# gem "sql-logging"

gem 'figaro', '~> 0.7.0'
gem 'pg_search', '~> 0.7.2'

# RABID: the official version of acts_as_versioned seems to be abandoned but
# 		 this fork claims to have rails 3 support
gem 'acts_as_versioned', git: 'https://github.com/jwhitehorn/acts_as_versioned.git', ref: '44dfe632ba8c97c786cbc172a2da18a41b17f668'

# RABID: the old plugin version of acts-as-taggable-on was 1.0.0
gem 'acts-as-taggable-on', '~> 3.3.0'

# RABID:
# Kete monkey patches attachment_fu a lot so we cannot track easily track the
# main version. You can see which attachment_fu ours was forked from (and when)
# by inspecting the repo on Github:
#   https://github.com/kete/attachment_fu/blob/master/attachment_fu.gemspec
#
# As I have discovered methods which patch AttachmentFu I have added a link to
# the original as a comment.  There are probably other places but at least the
# following classes & modules patch AttachmentFu:
#
# * ItemPrivacy::AttachmentFuOverload
# * ImageFile
# * OverrideAttachmentFuMethods
# * ResizeAsJpegWhenNecessary
#
gem 'pothoven-attachment_fu', git: 'https://github.com/kete/attachment_fu.git'

gem 'validate_url'

# ROB:  kete had it's own feedzirra which adds some extra functions needed by the
#       external_search_sources plugin.
#       It'll probably be possible to pull these function into external_search_sources
#       allowing us to use the stock feedzirra gem.
gem 'kete-feedzirra', git: 'https://github.com/kete/feedzirra'

# https://github.com/swanandp/acts_as_list
gem 'acts_as_list', '~> 0.3.0'

gem 'acts_as_configurable', '0.0.8'

# EOIN: piggy_back is an old implementation of AR #include e.g User.include(:roles).find.where(...) etc.
# gem "piggy_back", "#.#.#", :git => "git://github.com/shuber/sortable.git" # 2009-03-17

gem 'routing-filter', '~> 0.3.1'

gem 'oembed_provider_engine'

# gem "mysql"
gem 'pg'

gem 'awesome_nested_set', '~> 2.1.6'
gem 'railroady'

# Added to get rake working. I suspect these should be removed.
# gem 'rake', '0.9.2.2' # version needed to use: require 'rake/rdoctask'

gem 'rake', '< 11.0' # Remove this pin when you go to rails 4

# gem "rdoc"
gem 'nokogiri', '>= 1.8.1'

# Officially sanctioned Rails way to add Rails 2 stuff like #error_messages_for
# to Rails 3 projects
gem 'dynamic_form', '~> 1.1.4'

# Background tasks
# ################

gem 'backgroundrb-rails3', '~> 1.1.6', require: 'backgroundrb'
gem 'mini_exiftool', '< 2.0.0'
gem 'rmagick', '~> 2.16.0'

# Note: the file config/required_software.yml is a good place to look for things that would be needed in a bundler file.

gem 'oai', '~> 0.3.1'

gem 'hpricot'
gem 'packet'
gem 'redcarpet', '~> 3.2.3'

# #gem 'tiny_mce'
gem 'avatar'
# gem 'zoom'
gem 'chronic'
gem 'libxml-ruby'
gem 'ya2yaml'
# gem 'gmaps4rails', '1.4.2'

gem 'unicode'
gem 'xml-simple'
# gem 'system_timer'
gem 'mime-types'
# gem 'tiny_mce_plugin_imageselector', '>= 0.0.7'
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

gem 'active_scaffold', '~> 3.3.3'

# gem "acts_as_licensed", "#.#.#", :git => "git://github.com/shuber/sortable.git" # 2008-07-10
gem 'acts_as_soft_deletable', git: 'https://github.com/says/acts_as_soft_deletable.git' # 2009-02-16
## gem 'acts_as_zoom'
# gem 'auto_complete',                '0.0.1' # >> 2008-10-23
# gem 'backgroundrb-rails3',          '1.1.0' # >> 2008-10-15, replaces 'backgroundrb'
# gem 'better_nested_set',            '0.1.1' # >> 2008-08-04
# gem "brain_buster", "#.#.#", :git => "git://github.com/shuber/sortable.git" # 2009-05-25
# gem "bundle-fu", "#.#.#", :git => "git://github.com/shuber/sortable.git" # 2009-02-16
# gem "convert_attachment_to", "#.#.#", :git => "git://github.com/shuber/sortable.git" # 2008-07-10
# gem "external_search_sources", "#.#.#", :git => "git://github.com/shuber/sortable.git" # 2010-01-06
# gem 'foreign_key_migrations',       '0.3.0' # ~= 2008-06-30
# gem 'mimetype-fu',                  '0.1.1' # >> 2008-07-17
# gem "random_finders", "#.#.#", :git => "git://github.com/shuber/sortable.git" # 2007-12-07
# gem 'redbox',                       '1.0.3' # >> 2007-12-21
# gem 'redhillonrails_core',          '1.0.4' # >> 2008-06-30
# gem 'ssl_requirement',              '0.0.1' # >> 2008-05-29
# gem 'nove-system-settings',         '0.2.0' # >> 2008-01-14, replaces 'system_settings'
gem 'will_paginate', '~> 3.0.5'

# RABID: should be removed:
gem 'validates_xml', '1.0.3' # >> 2007-06-06

# ##############
# Authentication
# ##############

# Use auth in the old Kete included `acts_as_authenticated` gem which just
# provided some scaffolds that added code to your User model (and others).
# Since it does not contain any code itself we don't need to load it here but
# you might want to read its source to figure out how auth works:
# http://github.com/gundestrup/acts_as_authenticated

# The authorization gem has not been updated in years. We took this fork from a
# fork that had some fixes applied to make it work with Ruby 2.0. We are using
# our own fork to be sure that the repo will not be deleted in future.
gem 'authorization', git: 'https://github.com/kete/rails-authorization-plugin'

# ######
# Assets
# ######

# * These are usually in the :assets group in Rails 3.x projects but Heroku needs
#   them so we put them in the default (:production) group.
# * The only down-side to having them in production is that if you forget to
#   precompile your assets then Rails 3.x will compile them on the fly in
#   production. Rails 4 no longer does this.

gem 'coffee-rails', '~> 3.2.1'
gem 'compass-rails'
gem 'sass-rails'
gem 'uglifier', '>= 1.0.3'

gem 'strong_parameters'

# this doesn't make much sense, but heroku is complaining about not having this gem
gem 'test-unit', '~> 3.0'

group :development do
  gem 'quiet_assets'
  gem 'rails-erd'
end

group :development, :test do
  gem 'awesome_print'
  gem 'bundler-audit', '~> 0.3.1', require: false
  gem 'byebug'
  gem 'factory_girl_rails', '~> 4.5.0'
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'rspec-rails', '~> 3.5'
  gem 'rubocop', '0.49.1', require: false
end

group :test do
  gem 'capybara', '~> 2.4.4'
  gem 'database_cleaner', '~> 1.4.1'
  gem 'poltergeist'
  gem 'selenium-webdriver', '~> 2.45.0'
end

# Security updates
# https://github.com/tenderlove/psych/pull/187
gem 'psych', '> 2.0.5'
