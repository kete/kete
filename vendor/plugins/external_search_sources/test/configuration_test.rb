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
      :cache_results => false,
      :source_types => ['feed'],
      :source_targets => ["search", "homepage"],
      :limit_params => %w{ limit num_results count }
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
