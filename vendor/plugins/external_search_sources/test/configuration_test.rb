require 'test_helper'

class ConfigurationTest < ActiveSupport::TestCase

  test "ExternalSearchSources class has a settings value" do
    expected = {
      :authorized_role => "admin",
      :unauthorized_path => "/",
      :default_link_classes => "search_source-default-result",
      :image_link_classes => "search_source-image-result",
      :default_url_options => {},
      :login_method => :login_required,
      :source_targets => ["search", "homepage"],
      :cache_results => false
    }
    assert_equal expected, ExternalSearchSources.settings
  end

  test "ExternalSearchSources responds to getter method" do
    assert_equal 'admin', ExternalSearchSources[:authorized_role]
  end

  test "ExternalSearchSources responds to setter method" do
    ExternalSearchSources[:authorized_role] = 'someone'
    assert_equal 'someone', ExternalSearchSources[:authorized_role]
  end

end
