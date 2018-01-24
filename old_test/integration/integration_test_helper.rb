# Skip the system configuration steps when we load the environment/routes,
# because we'll set and reload routes later
SKIP_SYSTEM_CONFIGURATION = true

# Standard test initialization code
ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../../config/environment")
require 'rails/test_help'

# Require the <tt>common_test_methods</tt> file
require File.expand_path(File.dirname(__FILE__) + "/../common_test_methods")

# Load the libraries from installed gems required to run the tests
load_testing_libs

# Request permission to alter the Zebra database (if this has already been run,
# the environment check will just skip this step)
verify_zebra_changes_allowed

# Stop, initialize, start, and bootstrap the zebra databases ready for the tests
bootstrap_zebra_with_initial_records

# Load the factories we have (for quick user / basket generation)
require File.expand_path(File.dirname(__FILE__) + "/../factories")

# Overwrite all constants there may be with defaults so we can continue testing
configure_environment do
  require File.expand_path(File.dirname(__FILE__) + "/../system_configuration_constants")
end

# Turn off error 500 page opening (it's output to the console aleady)
# Turn the mode to rails as well (or we get errors)
if defined?(SELENIUM_MODE) && SELENIUM_MODE
  Webrat.configure do |config|
    config.mode = :selenium
    config.application_environment = :test
    config.open_error_files = false
  end
else
  Webrat.configure do |config|
    config.mode = :rails
    config.open_error_files = false
  end
end

# Overload the IntegrationTest class to ensure tear down occurs OK.
class ActionController::IntegrationTest
  include ZoomControllerHelpers

  # setup basket variables for use later
  @@site_basket ||= Basket.site_basket
  @@help_basket ||= Basket.help_basket
  @@about_basket ||= Basket.about_basket
  @@documentation_basket ||= Basket.documentation_basket

  # how many users/baskets do we have when we start these tests
  @@user_count = User.count
  @@basket_count = Basket.count

  # setup object creation variables for use later
  @@users_created = Array.new
  @@baskets_created = Array.new

  # Attempt to logout. Can be called anywhere (even without being logged in).
  def logout
    visit "/site/account/logout"
  end

  # Attempt to login. If we arn't on the login page aleady, we'll navigate to the login by first logging out
  # (see <tt>logout</tt>) visiting the root path (site basket homepage) and clicking the link "Login" in the
  # header. Then fill in fields and click "Log in" Takes required username, and optional password, whether to
  # navigate to login (not needed if we're there already) and whether we are expecting this login to fail
  def login_as(username, password = 'test', options = {})
    options = { :navigate_to_login => false,
                :by_form => false,
                :logout_first => false,
                :test_success => false,
                :should_fail_login => false }.merge(options)

    options[:logout_first] = true if options[:navigate_to_login]
    options[:test_success] = true if options[:navigate_to_login]

    if options[:logout_first]
      logout # make sure we arn't logged in first
    end

    if options[:navigate_to_login]
      visit "/site/account/login"
    end

    if options[:by_form]
      body_should_contain "Login to Kete"
      fill_in "login", :with => username.to_s
      fill_in "password", :with => password
      submit_form "login"
    else
      # we just want the user to have an authenticated state
      # no need to go through all the requests, etc.
      visit "/site/account/login", :post, { :login => username.to_s, :password => password }
    end

    body_should_contain("Logged in successfully") if options[:test_success] && !options[:should_fail_login]
  end

  # Asserts whether the supplied text is within the response body returned from a visit request.
  # Takes required text, optional options hash, which can set :number_of_times (how many occurances of text
  # should be on this page), and :dump_response option (which will output the entire response body (html
  # source) to the console)
  def body_should_contain(text, options = {})
    raise "body_should_contain method should be called after a page visit" if response.nil? || response.body.nil?
    response_body = response.body.squish
    unless text.kind_of?(Regexp)
      text = options[:escape_chars] ? escape(text.squish) : text.squish
    end
    save_and_open_page if options[:dump_response]
    if !options[:number_of_times].nil?
      occurances = response_body.scan(text).size
      assert (occurances == options[:number_of_times]),
             (options[:message] || "Body should contain '#{text}' #{options[:number_of_times]} times, but has #{occurances}.")
    else
      if text.kind_of?(Regexp)
        assert (response_body =~ text), (options[:message] || "Body should contain '#{text}', but does not.")
      else
        assert response_body.include?(text), (options[:message] || "Body should contain '#{text}', but does not.")
      end
    end
  end

  # Asserts whether the supplied text is not within the response body returned from a visit request.
  # Takes required text, optional options hash, which can set :number_of_times (how many occurances of text
  # should be on this page), and :dump_response option (which will output the entire response body (html
  # source) to the console)
  def body_should_not_contain(text, options = {})
    raise "body_should_not_contain method should be called after a page visit" if response.nil? || response.body.nil?
    response_body = response.body.squish
    unless text.kind_of?(Regexp)
      text = options[:escape_chars] ? escape(text.squish) : text.squish
    end
    save_and_open_page if options[:dump_response]
    if !options[:number_of_times].nil?
      occurances = response_body.scan(text).size
      assert !(occurances == options[:number_of_times]),
             (options[:message] || "Body should not contain '#{text}' #{options[:number_of_times]} times, but does.")
    else
      if text.kind_of?(Regexp)
        assert !(response_body =~ text), (options[:message] || "Body should not contain '#{text}', but does.")
      else
        assert !response_body.include?(text), (options[:message] || "Body should not contain '#{text}', but does.")
      end
    end
  end

  # UGLY METHOD - FIND BETTER WAY
  # Checks elements exist on a page in the order they are rendered. Pass in an array in the order they
  # should appear, and a divider which seperates each text in the array (a div, hr, new line etc)
  def body_should_contain_in_order(text_array, divider, options = {})
    raise "body_should_contain_in_order method should be called after a page visit" if response.nil? || response.body.nil?
    save_and_open_page if options[:dump_response]
    response_body = response.body.squish
    parts = response_body.split(divider).compact.flatten
    offset = options[:offset] ? options[:offset] : 0
    parts.each_with_index do |part, index|
      next if (index - offset) < 0 || text_array[(index - offset)].nil?
      assert part.include?(text_array[(index - offset)]), "#{text_array[(index - offset)]} is not in the right order it should be."
    end
  end

  # Asserts whether the supplied text is within the request url of the currently viewed page
  # Takes required text, optional options hash which can set :dump_response option (which will output the
  # entire request url to the console)
  def url_should_contain(text, options = {})
    puts request.url if options[:dump_response]
    if text.is_a?(Regexp)
      assert (request.url =~ text), "URL should contain '#{text}', but does not."
    else
      assert request.url.include?(text), "URL should contain '#{text}', but does not."
    end
  end

  # Asserts whether the supplied text is not within the request url of the currently viewed page
  # Takes required text, optional options hash which can set :dump_response option (which will output the
  # entire request url to the console)
  def url_should_not_contain(text, options = {})
    puts request.url if options[:dump_response]
    if text.is_a?(Regexp)
      assert !(request.url =~ text), "URL should not contain '#{text}', but does."
    else
      assert !request.url.include?(text), "URL should not contain '#{text}', but does."
    end
  end

  # Create a new item by navigating to the item new page, filling in fields and clicking "Create". While
  # this method works properly, it is advised you use the functionality provided by <tt>method_missing</tt>,
  # such as new_topic or new_audio_recording (which will save you having to provide the zoom_class on the
  # end as it automatically determines that from the method name).
  # Takes all optional parameters (which will be populated with defaults if they remain nil)
  # options takes a hash of field values to be filled in. basket takes Basket object where the item will be
  # added to. is_homepage_topic specifies if the topic should be created through the Baskets "Add new basket
  # homepage topic" option on the homepage options page.
  # If you plan to make a homepage topic, use <tt>new_homepage_topic</tt> instead as it provides a cleaner
  # syntax zoom_class specifies what type of item is being added. Should be the class of the item such as
  # Topic or AudioRecording
  def new_item(options = nil, basket = nil, is_homepage_topic = nil, zoom_class = nil)
    # because we use method missing, something like  new_topic()  (without any options) will return nil when
    # it calls this method and because of some funkyness in ruby, setting defaults in the options above is
    # replaced by nil, rather than the value so instead of setting it there, we set them here instead,
    # which should provide better support
    options = Hash.new if options.nil?
    basket = @@site_basket if basket.nil?
    is_homepage_topic = false if is_homepage_topic.nil?
    zoom_class = 'Topic' if zoom_class.nil?

    # Now we have the zoom_class, lets get the controller and field_prefix from it
    controller = zoom_class_controller(zoom_class)
    field_prefix = zoom_class.underscore

    # Set a bunch of default values to enter. Only title and description fields exist on every item so
    # only those can be set at this point. :new_path is also provided here, but later removed using
    # .delete(:new_path)
    fields = {
      :new_path => "/#{basket.urlified_name}/#{controller}/new",
      :title => "#{zoom_class_humanize(zoom_class)} Title",
      :description => "#{zoom_class_humanize(zoom_class)} Description",
      :success_message => "#{zoom_class_humanize(zoom_class)} was successfully created.",
      :relate_to => nil,
      :topic_type => "Topic"
    }
    fields.merge!(options)

    # If we're dealing with portraits, lets tack on params to the end of new_path
    if zoom_class == "StillImage"
      if fields.delete(:portrait)
        fields[:new_path] = "#{fields[:new_path]}?portrait=true"
        fields[:success_message] = "#{zoom_class_humanize(zoom_class)} was successfully created as a portrait."
      elsif fields.delete(:selected_portrait)
        fields[:new_path] = "#{fields[:new_path]}?selected_portrait=true"
        fields[:success_message] = "#{zoom_class_humanize(zoom_class)} was successfully created as your selected portrait."
      end
    end

    # Delete these here because they arn't fields and will <tt>get_webrat_actions_from</tt> to raise
    # an exception
    new_path = fields.delete(:new_path)
    success_message = fields.delete(:success_message)
    relate_to = fields.delete(:relate_to)
    go_to_related = fields.delete(:go_to_related)
    topic_type = fields.delete(:topic_type)
    should_fail_create = fields.delete(:should_fail)

    unless relate_to.nil? || relate_to.is_a?(Topic)
      raise "ERROR: You must relate an item to a Topic, not a #{relate_to.class.name}"
    end

    # If we are making a topic, and it is intended as a homepage, then make sure we append index_for_basket,
    # otherwise, if we are making a different item or a topic that isn't a homepage, browse directly to the
    # add item form for that type (created above as :new_path)
    if controller == 'topics' && is_homepage_topic
      visit "/#{basket.urlified_name}/topics/new?index_for_basket=#{basket.id}"
    elsif !relate_to.nil?
      visit "/#{relate_to.basket.urlified_name}/#{controller}/new?relate_to_item=#{relate_to.to_param}&relate_to_type=Topic"
    else
      visit new_path
    end

    # If we are making a Topic, it has one more step before we actually reach the new topic page, and that
    # is to provide a Topic Type
    if controller == 'topics'
      select(/#{topic_type}/, :from => "topic_topic_type_id")
      click_button("Choose Type")
    end

    # Convert the field values into webrat actions (strings to fields, booleans to radio buttons etc)
    get_webrat_actions_from(fields, field_prefix)

    # If we have been passed in a block of additional actions (because for example
    # <tt>get_webrat_actions_from</tt> doesn't support what we need), then yield that block here, passing
    # to it the field_prefix
    yield(field_prefix) if block_given?

    # With all fields filled in, create the item
    click_button "Create"

    # Get the last created item (the one created above)
    item = zoom_class.constantize.last

    # If we made a homepage, then we should gets text saying that we did so successfully,
    # otherwise we get test saying the Item was created successfully.
    if controller == 'topics' && is_homepage_topic
      if should_fail_create
        body_should_not_contain "Basket homepage was successfully created."
      else
        body_should_contain "Basket homepage was successfully created."
      end
    elsif !relate_to.nil?
      body_should_contain "Related #{zoom_class_humanize(zoom_class)} was successfully created."
      body_should_contain relate_to.title
      body_should_not_contain 'No Public Version Available'
      if item.latest_version_is_private?
        item.private_version!
        body_should_contain "#{item.title}"
        body_should_contain "/#{basket.urlified_name}/#{controller}/show/#{item.id}?private=true"
      else
        body_should_contain "#{item.title}"
        body_should_contain "/#{basket.urlified_name}/#{controller}/show/#{item.id}"
      end
      click_link "#{item.title}" if go_to_related.nil? || go_to_related
    else
      if should_fail_create
        body_should_not_contain success_message
      else
        body_should_contain success_message
      end
    end

    # Finally, lets return the last item of this type made (we assigned item earlier)
    item
  end

  # A quick method for adding a new homepage topic.
  # Takes both optional arguments. To see what should be supplied for options and basket, see the definition
  # of add_item above
  def new_homepage_topic(options = {}, basket = @@site_basket)
    # Homepage topics are always made through homepage topic form, and are always of class Topic,
    # so we can remove two arguments by supplyin them both here manually
    new_item(options, basket, true, 'Topic')
  end

  # Update the item with a set of values from either options or passed in as a block
  # Takes a required item argument (the Object of whatever item you're wanting to update),
  # and an optional options value, a hash of field values to be filled in
  def update_item(item, options = {})
    # Lets get the controller from the item passed in, the zoom_class from the controller, and the
    # field_prefix from the zoom_class
    controller = zoom_class_controller(item.class.name)
    zoom_class = zoom_class_from_controller(controller)
    field_prefix = zoom_class.underscore

    # Set a bunch of default values to enter. Only title and description fields exist on every item so
    # only those can be set at this point. :edit_path is also provided here, but later removed using
    # .delete(:edit_path)
    fields = {
      :edit_path => "/#{item.basket.urlified_name}/#{controller}/edit/#{item.to_param}",
      :title => "#{zoom_class_humanize(zoom_class)} Updated Title",
      :description => "#{zoom_class_humanize(zoom_class)} Updated Description",
      :success_message => "#{zoom_class_humanize(zoom_class)} was successfully updated."
    }
    fields[:edit_path] += "?private=true" if item.is_private?
    fields.merge!(options)
    # Delete these here because they arn't fields and will <tt>get_webrat_actions_from</tt> to raise an
    # exception
    edit_path = fields.delete(:edit_path)
    success_message = fields.delete(:success_message)

    # Visit the items edit url (formed from either the items values, or pass in the path manually using
    # :edit_path in the options param), and confirm we are on the right page
    visit edit_path

    body_should_contain "Editing #{zoom_class_humanize(zoom_class)}"

    # Convert the field values into webrat actions (strings to fields, booleans to radio buttons etc). See
    # the declartion of <tt>get_webrat_actions_from</tt> to see how this is done.
    get_webrat_actions_from(fields, field_prefix)

    # If we have been passed in a block of additional actions (because for example
    # <tt>get_webrat_actions_from</tt> doesn't support what we need), then yield that block here, passing to
    # it the field_prefix
    yield(field_prefix) if block_given?

    # With all fields filled in, update the item
    click_button "Update"

    # Confirm the item was successfully edited before continuing
    body_should_contain success_message

    # Finally, lets reload the item so the values are repopulated for use in later assertions
    item.reload
  end

  # Deletes an item by going to it's show page and clicking the "Delete" button
  # Takes a required item argument (the Object of whatever item you're wanting to delete)
  def delete_item(item)
    # Lets get the controller from the item passed in
    controller = zoom_class_controller(item.class.name)
    # Go to the items delete URL
    visit "/#{item.basket.urlified_name}/#{controller}/destroy/#{item.to_param}", :post
    # Confirm the item was deleted and we are redirected to the items browse page before continuing
    body_should_contain "Refine your results"
    # we actually want this to fail and return nil, it means the item was deleted properly
    begin
      return item.reload # if this works, its bad
    rescue
      return nil # if this gets called, thats good
    end
  end

  # Add a new basket via the forms (as apposed to create_new_method basket that creates the objects)
  # Optionally receives a block which could be webrat control methods run on the basket creation form
  # prior to clicking "Create". Returns the newly created basket instance.
  def new_basket(options = {})
    fields = { :name => "New basket" }
    fields.merge!(options)

    visit '/site/baskets/new'
    body_should_contain 'New basket'

    # Convert the field values into webrat actions (strings to fields, booleans to radio buttons etc). See
    # the declartion of <tt>get_webrat_actions_from</tt> to see how this is done.
    get_webrat_actions_from(fields, 'basket')

    yield('basket') if block_given?

    click_button 'Create'

    body_should_contain 'Basket was successfully created.'
    body_should_contain "#{fields[:name]} Edit"

    # Return the last basket (the basket we just created)
    basket = Basket.last
    @@baskets_created << basket
    basket
  end

  # Delete a basket via the Delete button from the Basket edit page
  # Takes require basket object. Returns true if basket was deleted or false if the basket still remains
  def delete_basket(basket)
    visit "/#{basket.urlified_name}/baskets/destroy/#{basket.to_param}", :post

    body_should_contain 'Basket was successfully deleted.'
    # should return to site basket, not sub basket
    body_should_contain 'Browse'
    body_should_not_contain 'Browse:'

    @@baskets_created.delete(basket)

    begin
      basket.reload
      false
    rescue
      true
    end
  end

  # Quick and easy flagging for any item
  # Takes item object and flag string/symbol
  def flag_item_with(item, flag, version = nil)
    version ||= item.version
    visit "/#{item.basket.urlified_name}/#{zoom_class_controller(item.class.name)}/flag_form/#{item.id}?flag=#{flag}&version=#{version}"
    fill_in 'message_', :with => 'Testing'
    click_button 'Flag'
    body_should_contain 'Thank you for your input. A moderator has been notified and will review the item in question. The item has been reverted to a non-contested version for the time being'
    item.reload # get the new version
  end

  # Restore a moderated item (make live).
  # Takes required item object, and optional options hash, that can set :version to the version of the item
  # you wish to make live (default version is the latest version of the item)
  def moderate_restore(item, options = {})
    item_class = item.class.name
    controller = zoom_class_controller(item_class)
    version = options[:version] || item.version - 1
    visit "/#{item.basket.urlified_name}/#{controller}/preview/#{item.id}?version=#{version}"
    save_and_open_page unless response.body.include?("Preview revision")
    body_should_contain 'Preview revision'
    click_link I18n.t('topics.preview_actions.make_live')
    body_should_contain "The content of this #{zoom_class_humanize(item_class)} has been approved
                         from the selected revision."
    item.reload # get the new version
  end

  # Reject a moderated item.
  # Takes a require item object, and an option options hash, that can set :message (the reason for
  # rejection), and :version of the version of the item you wish to reject (default version is the
  # latest version of the item)
  def moderate_reject(item, options = {})
    item_class = item.class.name
    controller = zoom_class_controller(item_class)
    message = options[:message] || ""
    version = options[:version] || item.version - 1
    visit "/#{item.basket.urlified_name}/#{controller}/preview/#{item.id}?version=#{version}"
    body_should_contain 'Preview revision'
    click_link 'reject'
    body_should_contain "Reject this revision"
    fill_in 'message_', :with => message
    click_button 'Reject'
    body_should_contain "This version of this #{zoom_class_humanize(item_class)} has been rejected.
                         The user who submitted the revision will be notified by email."
    item.reload # get the new version
  end

  # Turn on full moderation on a basket
  def turn_on_full_moderation(basket)
    visit "/#{basket.urlified_name}/baskets/edit/#{basket.id}"
    select "moderator views before item approved", :from => "settings_fully_moderated"
    click_button "Update"
    body_should_contain "Basket was successfully updated."
    assert_equal "true", basket.settings[:fully_moderated].to_s,
                 "Basket fully_moderated setting should be true, but is not."
  end

  # Turn off full moderation on a basket
  def turn_off_full_moderation(basket)
    visit "/#{basket.urlified_name}/baskets/edit/#{basket.id}"
    select "moderation upon being flagged", :from => "settings_fully_moderated"
    click_button "Update"
    body_should_contain "Basket was successfully updated."
    assert_equal "false", basket.settings[:fully_moderated].to_s,
                 "Basket fully_moderated setting should be false, but is not."
  end

  # Check that an item occurs in search results only once
  # Note that an important limitation of this method is that it only checks the first page of results,
  # and hence is not useful for big result sets.
  def should_appear_once_in_search_results(item, options = {})
    # Reload to ensure that item is progressed past moderation version
    item.reload

    options = {
      :title => item.title
    }.merge!(options)

    if item.title == BLANK_TITLE
      error = "You asked to check that item is in search results, but item is pending moderation."
      error += "\n\n#{item.inspect}\n\n#{item.versions.inspect}\n\n"
      raise error
    end

    visit "/#{item.basket.urlified_name}/all/#{zoom_class_controller(item.class.name)}/"

    basket_mention = item.basket == @@site_basket ? "" : item.basket.name + " "
    body_should_contain "Results in #{basket_mention}#{zoom_class_plural_humanize(item.class.name).downcase}"

    # We can't use the item title because it can appear several times legitimately.
    body_should_contain "item_#{item.id}_wrapper", :number_of_times => 1
    body_should_contain options[:title]
  end

  # Check that an item DOES NOT occur in search results
  # Note that an important limitation of this method is that it only checks the first page of results,
  # and hence is not useful for big result sets.
  def should_not_appear_in_search_results(item)
    visit "/#{item.basket.urlified_name}/all/#{zoom_class_controller(item.class.name)}/"

    basket_mention = item.basket == @@site_basket ? "" : item.basket.name + " "
    body_should_contain "Results in #{basket_mention}#{zoom_class_plural_humanize(item.class.name).downcase}"

    # We can't use the item title because it can appear several times legitimately.
    body_should_not_contain "item_#{item.id}_wrapper"
  end

  # Redefine the Webrat attach_file method because we repeat actions each time we use it
  # So lets put them in a method that reduces the code needed to get it to work, and then call
  # super passing in the values we generate. Still provide the option to overwrite the mime type
  # incase the one mimetype-fu tries to use is not compatible
  def attach_file(locator, filename, mime_type = nil)
    file_path = File.join(RAILS_ROOT, "test/fixtures/files/#{filename}")
    file = File.open(file_path)
    mime_type = File.mime_type?(file).split(';').first if mime_type.blank?
    file.close
    super(locator, file_path, mime_type)
  end

  # A quick way to attach the appropriate file when adding an item
  def fill_in_needed_information_for(zoom_class)
    case zoom_class
    when 'StillImage'
      attach_file "image_file_uploaded_data", "white.jpg"
    when 'Video'
      attach_file "video[uploaded_data]", "teststrip.mpg", "video/mpeg"
    when 'AudioRecording'
      attach_file "audio_recording[uploaded_data]", "Sin1000Hz.mp3"
    when 'Document'
      attach_file "document[uploaded_data]", "test.pdf"
    when 'WebLink'
      # Because web link needs to be unique, we add a random query param on the end
      fill_in "web_link[url]", :with => "http://google.co.nz/?q=#{rand}"
    end
  end

  # When a test is finished, reset the constants, and remove all users/baskets created, ready for the next test
  # Make sure we also call the super (parent) teardown method so things continue to run properly
  def teardown
    configure_environment do
      require File.expand_path(File.dirname(__FILE__) + "/../system_configuration_constants")
    end
    # at the end of tests, we get rid of all baskets and users created to prevent naming collisions
    @@users_created.each { |user| user.destroy }
    @@users_created = Array.new
    @@baskets_created.each { |basket| basket.destroy }
    @@baskets_created = Array.new
    # we need to ensure at the end of tests that we are left with only the users and baskets we started
    # the tests with. If there are more, they were added outside of the helpers, and this cannot be
    # permitted, or you'll run into unaccounted issues later with basket/login names already existing
    if User.count > @@user_count
      logins = User.all.collect { |user| user.login }
      raise "A user(s) was created outside of the standard helpers. Remaining ones are: #{logins.join(',')}"
    end
    if Basket.count > @@basket_count
      baskets = Basket.all.collect { |basket| basket.urlified_name }
      raise "A basket(s) was created outside of the standard helpers. Remaining ones are: #{baskets.join(',')}"
    end
    super
  end

  # Enables production mode simulation (page caching, template caching, all request are remote)
  # This means we get error 404's when normally we'd get error 500's. We can also test caches are
  # being cleared properly. Also clears the cache
  def enable_production_mode
    Rake::Task['tmp:cache:clear'].execute(ENV)
    ActionController::Base.consider_all_requests_local = false
    ActionController::Base.perform_caching = true
    ActionView::Base.cache_template_loading = true
  end

  # Disables production mode simulation (no page caching, no template caching, all request are local)
  # This means we get error 500's instead of 404's on some pages. We can also test things are working
  # properly before caching. Also clears the cache
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
  def method_missing(method_sym, *args, &block)
    method_name = method_sym.to_s
    if method_name =~ /^new_(\w+)$/
      # new_topic / new_audio_recording
      # takes basket and a hash of values, plus an optional block
      # provides a more readable option for the <tt>add_item</tt> declaration
      valid_zoom_types = ['topic', 'still_image', 'audio_recording', 'video', 'web_link', 'document']
      unless valid_zoom_types.include?($1)
        raise "ERROR: Invalid item type '#{$1}'. Must be one of #{valid_zoom_types.join(', ')}."
      end
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
      @user = create_new_user({ :login => $1 }.merge(args))
      baskets = [baskets] unless baskets.kind_of?(Array)
      baskets.each { |basket| @user.has_role($2, basket) }
      @@users_created << @user
      eval("@#{$1} = @user")
    elsif method_name =~ /^add_(\w+)_as_super_user$/
      # add_bob_as_super_user
      args = args[0] || Hash.new
      @user = create_new_user({ :login => $1 }.merge(args))
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
      @user = create_new_user({ :login => login }.merge(args))
      @user.add_as_member_to_default_baskets if add_to_baskets
      @@users_created << @user
      eval("@#{login} = @user")
    else
      super
    end
  end

  # This method exists in the test/factories.rb file, however, that file does not have access to the
  # @@baskets_created class variable, and so any baskets created using that method don't get deleted at
  # the end. We fix this by redefining the method, calling it's super, and setting what it returns here
  def create_new_basket(options)
    basket = super
    @@baskets_created << basket
    basket
  end

  # This method exists in the test/factories.rb file, however, that file does not have access to the
  # @@users_created class variable, and so any users created using that method don't get deleted at the
  # end. We fix this by redefining the method, calling it's super, and setting what it returns here
  def create_new_user(options)
    user = super
    @@users_created << user
    user
  end

  # Convert a hash of options to webrat actions
  # Current supports:
  #   String    ->  fill_in   (text fields)
  #   TrueClass ->  choose    (radio buttons)
  # If a field isn't supported here, it will raise and exception.
  # The field can still be added via the block syntax that add_item takes
  def get_webrat_actions_from(hash, field_prefix)
    hash.each do |key, value|
      if value.kind_of?(String)
        fill_in "#{field_prefix}_#{key}", :with => value.to_s
      elsif value.is_a?(TrueClass)
        choose "#{field_prefix}_#{key}"
      else
        raise "Don't know what to do with #{key} and value #{value}"
      end
    end
  end

  # Escapes the &, <, >, and " chars
  # Used when you enter content into fields which is saved into a database and then displayed on a page
  # They'll convert to htmlentities on display, so we need to do the same thing since body_should_contain
  # works on page source, not on the generated display
  def escape(text)
    text.gsub(/&/, '&amp;').gsub(/</, '&lt;').gsub(/>/, '&gt;').gsub(/"/, '&quot;')
  end

  # tranform an array of ids
  # to a hash suitable to post as params
  # as if checkboxes of ids with value true
  def item_checkbox_hash_from(*ids)
    item_checkbox_hash = Hash.new
    ids.each { |id| item_checkbox_hash[id.to_s] = "true" }
    item_checkbox_hash
  end

  # directly hit the link_related action
  # assumes relation_candidates are of the same class
  # by doing this through the web interface we trigger all the zebra interaction and cache clearing
  def add_relation_between(topic, zoom_class, *relation_candidate_ids)
    topic = topic.id.to_s if topic.is_a?(Topic)
    item_checkbox_hash = item_checkbox_hash_from(relation_candidate_ids)
    post '/site/search/link_related', :relate_to_item => topic, :relate_to_type => 'Topic', :related_class => zoom_class, :item => item_checkbox_hash
    assert_response :redirect
    # body_should_contain "Successfully added item relationships"
  end

  # shortcut to unlink related items
  def unlink_relation_between(topic, zoom_class, *relation_candidate_ids)
    topic = topic.id.to_s if topic.is_a?(Topic)
    item_checkbox_hash = item_checkbox_hash_from(relation_candidate_ids)
    post '/site/search/unlink_related', :relate_to_item => topic, :relate_to_type => 'Topic', :related_class => zoom_class, :item => item_checkbox_hash
    assert_response :redirect
    # body_should_contain "Successfully removed item relationships."
  end
end
