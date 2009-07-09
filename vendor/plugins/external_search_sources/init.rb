Dir[File.join("#{File.dirname(__FILE__)}/config/locales/*.yml")].each do |locale|
  I18n.load_path.unshift(locale)
end

ActionController::Base.send(:helper, SearchSourcesHelper)

require 'external_search_sources'
