require 'test_helper'
# TODO: replace with mock if we start using mocks more frequently
require 'ostruct'

class RedirectRegistrationTest < ActiveSupport::TestCase
  setup do
    @redirect_registration = RedirectRegistration.create!(
      :source_url_pattern => '/foo/',
      :target_url_pattern => '/bar/'
    )
  end

  test "should match request" do
    set_request

    assert_not_nil RedirectRegistration.match(@request).first
  end

  test "should not match request" do
    set_request

    @request.url = "http://host/en/bar/bas"
    assert_nil RedirectRegistration.match(@request).first
  end

  # for some reason simply creating @request in setup wasn't working
  def set_request
    @request = OpenStruct.new
    @request.url = "http://host/en/foo/bas"
    @request.protocol = "http://"
    @request.host = "host"
  end
end
