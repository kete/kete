# Skip the system configuration steps when we load the environment/routes, because we'll set and reload routes later
SKIP_SYSTEM_CONFIGURATION = true

# Standard test initialization code
ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../../config/environment")
require 'test_help'

# Require the <tt>common_test_methods</tt> file
require File.expand_path(File.dirname(__FILE__) + "/../common_test_methods")

# Load the libraries from installed gems required to run the tests
load_testing_libs

# Request permission to alter the Zebra database (if this has already been run, the environment check will just skip this step)
verify_zebra_changes_allowed

# Stop, initialize, start, and bootstrap the zebra databases ready for the tests
bootstrap_zebra_with_initial_records

# Load the factories we have (for quick user / basket generation)
require File.expand_path(File.dirname(__FILE__) + "/../factories")

# Overwrite all constants there may be with defaults so we can continue testing
configure_environment do
  require File.expand_path(File.dirname(__FILE__) + "/../system_configuration_constants")
end

# Overload the IntegrationTest class to ensure tear down occurs OK.
class ActionController::IntegrationTest

  include ZoomControllerHelpers

  # setup basket variables for use later
  @@site_basket ||= Basket.site_basket
  @@help_basket ||= Basket.help_basket
  @@about_basket ||= Basket.about_basket
  @@documentation_basket ||= Basket.documentation_basket
  
  # setup object creation variables for use later
  @@users_created = Array.new
  @@baskets_created = Array.new

  # Attempt to logout. Can be called anywhere (even without being logged in).
  def logout
    visit "/site/account/logout"
  end

  # Attempt to login. If we arn't on the login page aleady, we'll navigate to the login by first logging out (see <tt>logout</tt>)
  # visiting the root path (site basket homepage) and clicking the link "Login" in the header. Then fill in fields and click "Log in"
  # Takes required username, and optional password, whether to navigate to login (not needed if we're there already) and whether we
  # are expecting this login to fail
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

  # Asserts whether the supplied text is within the response body returned from a visit request.
  # Takes required text, optional message (if not provided, message will be auto generated), and dump_response option (which will
  # output the entire response body (html source) to the console)
  def body_should_contain(text, message = nil, dump_response = false)
    message = "Body should contain '#{text}', but does not." if message.nil?
    dump(response.body) if dump_response
    assert response.body.include?(text), message
  end

  # Asserts whether the supplied text is not within the response body returned from a visit request.
  # Takes required text, optional message (if not provided, message will be auto generated), and dump_response option (which will
  # output the entire response body (html source) to the console)
  def body_should_not_contain(text, message = nil, dump_response = false)
    message = "Body should not contain '#{text}', but does." if message.nil?
    dump(response.body) if dump_response
    assert !response.body.include?(text), message
  end
  
  # Asserts whether the supplied text is within the request url of the currently viewed page
  # Takes required text, optional message (if not provided, message will be auto generated), and dump_response option (which will
  # output the entire request url to the console)
  def url_should_contain(text, message = nil, dump_response = false)
    message = "URL should contain '#{text}', but does not." if message.nil?
    dump(request.url) if dump_response
    assert request.url.include?(text), message
  end

  # Asserts whether the supplied text is not within the request url of the currently viewed page
  # Takes required text, optional message (if not provided, message will be auto generated), and dump_response option (which will
  # output the entire request url to the console)
  def url_should_not_contain(text, message = nil, dump_response = false)
    message = "URL should not contain '#{text}', but does." if message.nil?
    dump(request.url) if dump_response
    assert !request.url.include?(text), message
  end

  # Create a new item by navigating to the item new page, filling in fields and clicking "Create". While this method works properly,
  # it is advised you use the functionality provided by <tt>method_missing</tt>, such as add_topic or add_audio_recording (which will
  # save you having to provide the zoom_class on the end as it automatically determines that from the method name)
  # Takes all optional parameters (which will be populated with defaults if they remain nil)
  # args takes a hash of field values to be filled in. basket takes Basket object where the item will be added to. is_homepage_topic
  # specifies if the topic should be created through the Baskets "Add new basket homepage topic" option on the homepage options page.
  # If you plan to make a homepage topic, use <tt>new_homepage_topic</tt> instead as it provides a cleaner syntax
  # zoom_class specifies what type of item is being added. Should be the class of the item such as Topic or AudioRecording
  def new_item(args = nil, basket = nil, is_homepage_topic = nil, zoom_class = nil)
    # because we use method missing, something like  new_topic()  (without any args) will return nil when it calls this method
    # and because of some funkyness in ruby, setting defaults in the args above is replaced by nil, rather than the value
    # so instead of setting it there, we set them here instead, which should provide better support
    args = Hash.new if args.nil?
    basket = @@site_basket if basket.nil?
    is_homepage_topic = false if is_homepage_topic.nil?
    zoom_class = 'Topic' if zoom_class.nil?

    # Now we have the zoom_class, lets get the controller and field_prefix from it
    controller = zoom_class_controller(zoom_class)
    field_prefix = zoom_class.underscore

    # Set a bunch of default values to enter. Only title and description fields exist on every item so only those
    # can be set at this point. :new_path is also provided here, but later removed using .delete(:new_path)
    fields = { :new_path => "/#{basket.urlified_name}/#{controller}/new",
               :title => "#{zoom_class_humanize(zoom_class)} Title",
               :description => "#{zoom_class_humanize(zoom_class)} Description" }
    fields.merge!(args) unless args.nil?
    new_path = fields.delete(:new_path)

    # If we are making a topic, and it is intended as a homepage, then browse to the homepage options and click on the "Add new basket
    # homepage topic" link, otherwise, if we are making a different item or a topic that isn't a homepage, browse directly to the 
    # add item form for that type (created above as :new_path) 
    if controller == 'topics' && is_homepage_topic
      visit "/#{basket.urlified_name}/baskets/homepage_options/#{basket.id}"
      click_link "Add new basket homepage topic"
    else
      visit new_path
    end

    # If we are making a Topic, it has one more step before we actually reach the new topic page, and that is to provide a Topic Type
    click_button("Choose Type") if controller == 'topics'

    # Convert the field values into webrat actions (strings to fields, booleans to radio buttons etc)
    get_webrat_actions_from(fields, field_prefix)

    # If we have been passed in a block of additional actions (because for example <tt>get_webrat_actions_from</tt> doesn't support
    # what we need), then yield that block here, passing to it the field_prefix
    yield(field_prefix) if block_given?
    
    # With all fields filled in, create the item
    click_button "Create"

    # If we made a homepage, then we should gets text saying that we did so successfully,
    # otherwise we get test saying the Item was created successfully.
    if controller == 'topics' && is_homepage_topic
      body_should_contain "Basket homepage was successfully created."
    else
      body_should_contain "#{zoom_class_humanize(zoom_class)} was successfully created."
    end

    # Finally, lets return the last item of this type made (which will be the one we just created).
    zoom_class.constantize.last
  end

  # A quick method for adding a new homepage topic.
  # Takes both optional arguments. To see what should be supplied for args and basket, see the definition of add_item above
  def new_homepage_topic(args = {}, basket = @@site_basket)
    # Homepage topics are always made through homepage topic form, and are always of class Topic,
    # so we can remove two arguments by supplyin them both here manually
    new_item(args, basket, true, 'Topic')
  end

  # Update the item with a set of values from either args or passed in as a block
  # Takes a required item argument (the Object of whatever item you're wanting to update),
  # and an optional args value, a hash of field values to be filled in
  def update_item(item, args = {})
    # Lets get the controller from the item passed in, the zoom_class from the controller, and the field_prefix from the zoom_class
    controller = zoom_class_controller(item.class.name)
    zoom_class = zoom_class_from_controller(controller)
    field_prefix = zoom_class.underscore

    # Set a bunch of default values to enter. Only title and description fields exist on every item so only those
    # can be set at this point. :edit_path is also provided here, but later removed using .delete(:edit_path)
    fields = { :edit_path => "/#{item.basket.urlified_name}/#{controller}/edit/#{item.to_param}",
               :title => "#{zoom_class_humanize(zoom_class)} Updated Title",
               :description => "#{zoom_class_humanize(zoom_class)} Updated Description" }
    fields.merge!(args) unless args.nil?
    edit_path = fields.delete(:edit_path)

    # Visit the items edit url (formed from either the items values, or pass in the path manually using :edit_path in the args param),
    # and confirm we are on the right page
    visit edit_path
    
    body_should_contain "Editing #{zoom_class_humanize(zoom_class)}"
    
    # Convert the field values into webrat actions (strings to fields, booleans to radio buttons etc). See the declartion of
    # <tt>get_webrat_actions_from</tt> to see how this is done.
    get_webrat_actions_from(fields, field_prefix)
    
    # If we have been passed in a block of additional actions (because for example <tt>get_webrat_actions_from</tt> doesn't support
    # what we need), then yield that block here, passing to it the field_prefix
    yield(field_prefix) if block_given?
    
    # With all fields filled in, update the item
    click_button "Update"

    # Confirm the item was successfully edited before continuing
    body_should_contain "#{zoom_class_humanize(zoom_class)} was successfully updated."

    # Finally, lets reload the item so the values are repopulated for use in later assertions
    item.reload
  end

  # Deletes an item by going to it's show page and clicking the "Delete" button
  # Takes a required item argument (the Object of whatever item you're wanting to delete)
  def delete_item(item)
    # Lets get the controller from the item passed in 
    controller = zoom_class_controller(item.class.name)
    # Go to the items show page and click the Delete button
    visit "/#{item.basket.urlified_name}/#{controller}/show/#{item.to_param}"
    click_link "Delete"
    # Confirm the item was deleted and we are redirected to the items browse page before continuing
    body_should_contain "Refine your results"
    # we actually want this to fail and return nil, it means the item was deleted properly
    begin
      return item.reload  # if this works, its bad
    rescue
      return nil  # if this gets called, thats good
    end
  end

  # Add a new basket
  # Optionally receives a block which could be webrat control methods run on the basket creation form
  # prior to clicking "Create".
  # Returns the newly created basket instance.
  def new_basket(name = "New basket", privacy_controls = false, &block)
    visit '/site/baskets/new'
    body_should_contain 'New basket'

    fill_in 'basket[name]', :with => name

    privacy_controls ? choose('basket_show_privacy_controls_true') : \
      choose('basket_show_privacy_controls_false')

    yield(block) if block_given?

    click_button 'Create'

    body_should_contain 'Basket was successfully created.'
    body_should_contain "#{name} Edit"

    # Return the last basket (the basket we just created)
    basket = Basket.last
    @@baskets_created << basket
    basket
  end

  # The "delete this basket" link requires JavaScript due to a confirm method, etc.
  # We will need to add a Selenium test to run this method.
  def delete_basket(name)
    raise "Not implemented."
  end

  # When a test is finished, reset the constants, and remove all users/baskets created, ready for the next test
  # Make sure we also call the super (parent) teardown method so things continue to run properly
  def teardown
    configure_environment do
      require File.expand_path(File.dirname(__FILE__) + "/../system_configuration_constants")
    end
    @@users_created.each { |user| user.destroy }
    @@users_created = Array.new
    @@baskets_created.each { |basket| basket.destroy }
    @@baskets_created = Array.new
    super
  end

  # Enables production mode simulation (page caching, template caching, all request are remote)
  # This means we get error 404's when normally we'd get error 500's. We can also test caches are being cleared properly
  # Also clears the cache
  def enable_production_mode
    Rake::Task['tmp:cache:clear'].execute(ENV)
    ActionController::Base.consider_all_requests_local = false
    ActionController::Base.perform_caching = true
    ActionView::Base.cache_template_loading = true
  end

  # Disables production mode simulation (no page caching, no template caching, all request are local)
  # This means we get error 500's instead of 404's on some pages. We can also test things are working properly before caching
  # Also clears the cache
  def disable_production_mode
    ActionView::Base.cache_template_loading = false
    ActionController::Base.perform_caching = false
    ActionController::Base.consider_all_requests_local = true
    Rake::Task['tmp:cache:clear'].execute(ENV)
  end

  private

  # We define a variety methods that are created on the fly, to make writing tests easier. These methods include
  #   new_[item_type]    (e.g.  new_audio_recording, a quick method that passes the arguments to <tt>add_item</tt>)
  #   add_[name]_as_[role]_to (e.g. add_bob_as_moderator_to(@@site_basket), a quick way to add users needed for testing)
  #   add_[name]_as_super_user (e.g. add_joe_as_super_user, adds jow as site/tech admin in site basket and admin in all others)
  #   add_[name]_as_regular_user (e.g. add_jane_as_regular_user, adds jane as a member to default baskets (site, help, about, docs))
  #   add_[name] (e.g. add_jill, add jill but without any roles on any baskets)
  # Each user action automatically assigns an instance variable by the same name as the one provided in the method declaration
  # If a method doesn't match any of these, it is passed up to the super (parent) method_missing declaration
  def method_missing( method_sym, *args, &block )
    method_name = method_sym.to_s
    if method_name =~ /^new_(\w+)$/
      # new_topic / new_audio_recording
      # takes basket and a hash of values, plus an optional block
      # provides a more readable option for the <tt>add_item</tt> declaration
      valid_zoom_types = ['topic', 'still_image', 'audio_recording', 'video', 'web_link', 'document']
      raise "ERROR: Invalid item type '#{$1}'. Must be one of #{valid_zoom_types.join(', ')}." unless valid_zoom_types.include?($1)
      if block_given?
        new_item(args[0], args[1], args[2], $1.classify, &block)
      else
        new_item(args[0], args[1], args[2], $1.classify)
      end
    elsif method_name =~ /^add_(\w+)_as_(\w+)_to$/
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

  # Convert a hash of options to webrat actions
  # Current supports:
  #   String    ->  fill_in   (text fields)
  #   TrueClass ->  choose    (radio buttons)
  # If a field isn't supported here, it will raise and exception.
  # The field can still be added via the block syntax that add_item takes
  def get_webrat_actions_from(hash, field_prefix)
    hash.each do |key,value|
      if value.kind_of?(String)
        fill_in "#{field_prefix}_#{key.to_s}", :with => value.to_s
      elsif value.is_a?(TrueClass)
        choose "#{field_prefix}_#{key.to_s}"
      else
        raise "Don't know what to do with #{key} and value #{value}"
      end
    end
  end

  # Debugging method used in the [body|url]_should[_not]_contain methods
  # Shouldn't be used in tests though, so making this method private
  def dump(text)
    puts "-----------------"
    puts text
    puts "-----------------"
  end

end
