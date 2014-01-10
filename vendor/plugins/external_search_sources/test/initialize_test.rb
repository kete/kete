require 'test_helper'

class InitializeTest < ActiveSupport::TestCase

  test "The locales are added to the I18n load path" do
    locale_path = File.expand_path("#{File.dirname(__FILE__).gsub('/test', '')}/config/locales/en.yml")
    assert I18n.load_path.any? { |l| l.include?(locale_path) }
  end

end
