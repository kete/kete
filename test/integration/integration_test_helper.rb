# Skip the system configuration steps
SKIP_SYSTEM_CONFIGURATION = true

ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../../config/environment")
require 'test_help'
require File.expand_path(File.dirname(__FILE__) + "/../common_test_methods")
require File.expand_path(File.dirname(__FILE__) + "/../factories")

# James - 2008-12-08
# Load webrat for integration tests
require 'webrat/rails'

# Kieran - 2008-12-09
# Load shoulda for testing
require 'shoulda/rails'

def configure_environment(&block)
  yield(block)
  # Reload the routes based on the current configuration
  ActionController::Routing::Routes.reload!
end

configure_environment do
  require File.join(File.dirname(__FILE__), 'system_configuration_constants.rb')
end

ensure_zebra_running

# Overload the IntegrationTest class to ensure tear down occurs OK.
class ActionController::IntegrationTest
  # setup basket variables for use later
  @@site_basket ||= Basket.site_basket
  @@help_basket ||= Basket.help_basket
  @@about_basket ||= Basket.about_basket
  @@documentation_basket ||= Basket.documentation_basket

  def logout
    visit "/site/account/logout"
  end

  def login_as(username, password='test', navigate_to_login=true)
    if navigate_to_login
      logout # make sure we arn't logged in first
      visit "/"
      click_link "Login"
    end
    body_should_contain "Login to Kete"
    fill_in "login", :with => username
    fill_in "password", :with => password
    click_button "Log in"
  end

  def body_should_contain(text, message = nil, dump_response = false)
    message = "Body should contain '#{text}', but does not." if message.nil?
    dump(response.body) if dump_response
    assert response.body.include?(text), message
  end

  def body_should_not_contain(text, message = nil, dump_response = false)
    message = "Body should not contain '#{text}', but does." if message.nil?
    dump(response.body) if dump_response
    assert !response.body.include?(text), message
  end

  def url_should_contain(text, message = nil, dump_response = false)
    message = "URL should contain '#{text}', but does not." if message.nil?
    dump(request.url) if dump_response
    assert request.url.include?(text), message
  end

  def url_should_not_contain(text, message = nil, dump_response = false)
    message = "URL should not contain '#{text}', but does." if message.nil?
    dump(request.url) if dump_response
    assert !request.url.include?(text), message
  end

  # Debugging method
  def dump(text)
    puts "-----------------"
    puts text
    puts "-----------------"
  end

  # When a test is finished, reset the constants, and remove all users for the new test
  def teardown
    configure_environment do
      require File.join(File.dirname(__FILE__), 'system_configuration_constants.rb')
    end
    User.destroy_all
    super
  end

  private

  # this shouldn't be called directly, use the method missing functionality to add users on the fly
  # add_bob_as_tech_admin(:baskets => @@site_basket)
  def create_new_user(args)
    @user = User.find_by_login(args[:login])
    return @user unless @user.nil?
    @user = Factory(:user, args)
    assert_kind_of User, @user
    @user
  end

  def method_missing( method_sym, *args )
    method_name = method_sym.to_s
    if method_name =~ /^add_(\w+)_as_(\w+)_to$/
      # add_bob_as_moderator_to(@@site_basket)
      # can take single basket, or an array of them
      baskets = args[0] || Array.new
      args = args[1] || Hash.new
      @user = create_new_user({:login => $1}.merge(args))
      baskets = [baskets] unless baskets.kind_of?(Array)
      baskets.each { |basket| @user.has_role($2, basket) }
      eval("@#{$1} = @user")
    elsif method_name =~ /^add_(\w+)_as_super_user$/
      # add_bob_as_super_user
      args = args[0] || Hash.new
      @user = create_new_user({:login => $1}.merge(args))
      @user.has_role('site_admin', @@site_basket)
      @user.has_role('tech_admin', @@site_basket)
      Basket.all(:conditions => ["id != 1"]).each { |basket| @user.has_role('admin', basket) }
      eval("@#{$1} = @user")
    elsif method_name =~ /^add_(\w+)$/
      # add_bob_as_regular_user
      # add_john
      login = $1
      add_to_baskets = false
      if $1 =~ /^(\w+)_as_regular_user$/
        login = $1
        add_to_baskets = true
      end
      args = args[0] || Hash.new
      @user = create_new_user({:login => login}.merge(args))
      @user.add_as_member_to_default_baskets if add_to_baskets
      eval("@#{login} = @user")
    else
      super
    end
  end

end
