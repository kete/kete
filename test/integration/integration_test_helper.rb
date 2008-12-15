# Skip the system configuration steps
SKIP_SYSTEM_CONFIGURATION = true

ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../../config/environment")
require 'test_help'

require File.expand_path(File.dirname(__FILE__) + "/../common_test_methods")

load_testing_libs
require 'rake'
require 'rake/rdoctask'
require 'rake/testtask'
require 'tasks/rails'
verify_zebra_changes_allowed

require File.expand_path(File.dirname(__FILE__) + "/../factories")

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

  include ZoomControllerHelpers

  # setup basket variables for use later
  @@site_basket ||= Basket.site_basket
  @@help_basket ||= Basket.help_basket
  @@about_basket ||= Basket.about_basket
  @@documentation_basket ||= Basket.documentation_basket
  @@users_created = Array.new

  def logout
    visit "/site/account/logout"
  end

  def login_as(username, password='test', navigate_to_login=true, should_fail_login=false)
    if navigate_to_login
      logout # make sure we arn't logged in first
      visit "/"
      click_link "Login"
    end
    body_should_contain "Login to Kete"
    fill_in "login", :with => username
    fill_in "password", :with => password
    click_button "Log in"
    body_should_contain("Logged in successfully") unless should_fail_login
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

  def new_item(basket, zoom_class, homepage_topic = false, title='Homepage Title', description='Homepage Description')
    controller = zoom_class_controller(zoom_class)
    field_prefix = zoom_class.underscore
    if controller == 'topics' && homepage_topic
      visit "/#{basket.urlified_name}/baskets/homepage_options/#{basket.id}"
      click_link "Add new basket homepage topic"
    else
      visit "/#{basket.urlified_name}/#{controller}/new"
    end
    if controller == 'topics'
      click_button("Choose Type")
    end
    fill_in "#{field_prefix}_title", :with => title
    fill_in "#{field_prefix}_description", :with => description
    yield(field_prefix) if block_given?
    click_button "Create"
    if controller == 'topics' && homepage_topic
      body_should_contain "Basket homepage was successfully created."
    else
      body_should_contain "#{zoom_class_humanize(zoom_class)} was successfully created."
    end
    zoom_class.constantize.last # return the last item made (the one created above)
  end

  def update_item(item, title='Homepage Title Updated', description='Homepage Description Updated')
    controller = zoom_class_controller(item.class.name)
    zoom_class = zoom_class_from_controller(controller)
    field_prefix = zoom_class.underscore
    visit "/#{item.basket.urlified_name}/#{controller}/edit/#{item.to_param}"
    body_should_contain "Editing #{zoom_class_humanize(zoom_class)}"
    fill_in "#{field_prefix}_title", :with => title
    fill_in "#{field_prefix}_description", :with => description
    yield(field_prefix) if block_given?
    click_button "Update"
    body_should_contain "#{zoom_class_humanize(zoom_class)} was successfully edited."
    item.reload # update the instace var with the latest information
  end

  def delete_item(item)
    controller = zoom_class_controller(item.class.name)
    visit "/#{item.basket.urlified_name}/#{controller}/show/#{item.to_param}"
    click_link "Delete"
    body_should_contain "Refine your results"
    nil # return nil (to simulate an item deletion)
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
    @@users_created.each { |user| user.destroy }
    @@users_created = Array.new
    super
  end

  def enable_caching
    Rake::Task['tmp:cache:clear'].execute(ENV)
    ActionController::Base.perform_caching = true
    ActionView::Base.cache_template_loading = true
  end

  def disable_caching
    ActionView::Base.cache_template_loading = false
    ActionController::Base.perform_caching = false
    Rake::Task['tmp:cache:clear'].execute(ENV)
  end

  private

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
      @@users_created << @user
      eval("@#{$1} = @user")
    elsif method_name =~ /^add_(\w+)_as_super_user$/
      # add_bob_as_super_user
      args = args[0] || Hash.new
      @user = create_new_user({:login => $1}.merge(args))
      @user.has_role('site_admin', @@site_basket)
      @user.has_role('tech_admin', @@site_basket)
      Basket.all(:conditions => ["id != 1"]).each { |basket| @user.has_role('admin', basket) }
      @@users_created << @user
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
      @@users_created << @user
      eval("@#{login} = @user")
    else
      super
    end
  end

end
