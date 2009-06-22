['en'].each do |locale|
  I18n.load_path << File.dirname(__FILE__) + "/config/locales/#{locale}.yml"
end

ActionController::Base.send(:helper, SearchSourcesHelper)

require 'external_search_sources'
