#
# A collection of methods shared between the unit/functional and integration
# test helpers
#

# The <tt>load_testing_libs</tt> method relies on methods in the
# RequiredSoftware module
include RequiredSoftware

# Load the gems needed, pass it to the <tt>missing_libs</tt> method which will
# return an array of missing gem dependancies Takes an optional args parameter
# which, at the moment, only allows you to exclude which gems get loaded through
# :exclude If there are gems missing (i.e. the missing_gems array is not blank)
# then output which are missing and exit the execution
def load_testing_libs(args = {})
  missing_gems = missing_libs(load_required_software, 'testing_gems', args)
  unless missing_gems.blank?
    puts "ERROR: Not all the nessesary gems are installed for these Tests to run."
    puts "Please run 'rake manage_gems:testing:install' to install them then try again."
    puts "Missing #{missing_gems.join(', ')}"
    exit
  end
end

# Currently the tests use the Zebra instance configured for the
# development/production mode, so when tests are run, the data in the database
# is overwritten, and this can be bad if you run it in a production host. So
# prevent accidental data manipulation we provide the person running the test a
# chance to back out, making it clear that Zebra will be affected if they
# continue. We use a ZEBRA_CHANGES_PERMITTED environment variable so that the
# prompt only occurs once per testing session, rather than 3 times for each test
# type when 'rake test' is run
def verify_zebra_changes_allowed
  return if ENV['ZEBRA_CHANGES_PERMITTED']
  puts "\n/!\\ IMPORTANT /!\\\n\n"
  puts "Testing currently uses the Zebra instance for this Kete codebase and will add, update and remove records from it.\n\n"
  puts "Do not run these tests unless you're sure that the Zebra search engine is not being used on a production host!\n\n"
  puts "To skip this warning in the future, set the ZEBRA_CHANGES_PERMITTED environmental variable to true.  I.e. \"ZEBRA_CHANGES_PERMITTED=true; export ZEBRA_CHANGES_PERMITTED\" in your bash shell session.\n\n"
  puts "Press any key to continue, or Ctrl+C to abort before any changes are made.."
  STDIN.gets
  ENV['ZEBRA_CHANGES_PERMITTED'] = 'true'
end

# Include the necessary rake libraries for running Rake tasks within the tests.
# These are used for operations such as stopping/starting the Zebra database in
# <tt>bootstrap_zebra_with_initial_records</tt> and for clearing the tmp cache
require 'rake'
require 'rake/rdoctask'
require 'rake/testtask'
require 'tasks/rails'

# Stop Zebra if it is running, initilize the databases (wiping them clean),
# start zebra, and load in some initial records ready for testing. If after
# that, Zebra has not loaded properly, raise an exception to inform the person
# running the tests
def bootstrap_zebra_with_initial_records(prime_records = false)
  # both of the silencers are need to supress the two types of messages Zebra
  # outputs to the console
  silence_stream(STDERR) do
    silence_stream(STDOUT) do
      Rake::Task['zebra:stop'].execute(ENV) if zebra_running?('public') || zebra_running?('private')
      ENV['ZEBRA_DB'] = 'public'
      Rake::Task['zebra:init'].execute(ENV)
      ENV['ZEBRA_DB'] = 'private'
      Rake::Task['zebra:init'].execute(ENV)
      Rake::Task['zebra:start'].execute(ENV)
      Rake::Task['zebra:load_initial_records'].execute(ENV)

      # put in the default records, if specified
      if prime_records
        ZOOM_CLASSES.each do |name|
          name.constantize.all.each do |record|
            record.prepare_and_save_to_zoom
          end
        end
      end
    end
  end
  unless zebra_running?('public') && zebra_running?('private')
    raise "ERROR: Zebra's public and private databases failed to start up properly. Double check configuration and try again."
  end
end

# Checks whether a Zebra database of a certain type (public or private) is
# currently running. If a query succeeds then its running and we return true,
# else we capture the exception when it fails, and return false
def zebra_running?(zebra_db)
  zoom_db = ZoomDb.find_by_database_name(zebra_db)
  Topic.process_query(:zoom_db => zoom_db, :query => "@attr 1=_ALLRECORDS @attr 2=103 ''")
  return true
rescue
  return false
end

# To change a constant, use this method. It removes any existing constant and
# sets the new one from the arguments passed in If silence_warnings is available
# (which suppresses any output to the console) then we use it, else don't worry
# warnings and continue to run it anyway. Should be used within the block of
# <tt>configure_environment</tt>
def set_constant(constant, value)
  # Walter McGinnis, 2010-10-15
  # update to also update Kete object with value via redefining getter method
  Kete.define_reader_method_as(constant.to_s.downcase, value)

  if respond_to?(:silence_warnings)
    silence_warnings do
      Object.send(:remove_const, constant) if Object.const_defined?(constant)
      Object.const_set(constant, value)
    end
  else
    Object.send(:remove_const, constant) if Object.const_defined?(constant)
    Object.const_set(constant, value)
  end
end

# Takes a block of <tt>set_constant</tt> declarations, executes it, then reloads
# the routes (this method is used to setup Kete without running through the
# setup process)
def configure_environment(&block)
  yield(block)
  # Reload the routes based on the current configuration
  ActionController::Routing::Routes.reload!
end

# Similar to Rails fixture_file_upload, but with a different method name so we
# don't overwrite the existing one, and globally available, not just in
# controller tests (so factories can use it)
def upload_fixture_file(path, mime_type = nil, binary = false)
  ActionController::TestUploadedFile.new("#{RAILS_ROOT}/test/fixtures/files/#{path}", mime_type, binary)
end

#
# We use the following extended field methods in unit and integration tests for
# the content type and topic type filed mapping tests
#

# Fetch a mapping, destroy all its items (so we don't get tests failing because
# of existing data) Destroy all previous mappings, then create one option single
# value extended fields, and dependings on the options passed in either an
# options multiple or a required multiple. reload the object, get the new
# mappings, and return an array
def setup_mappings_of_class(type_class, zoom_or_topic_type_class, make_one_required = false)
  if type_class == 'TopicType'
    type = type_class.constantize.find_by_name(zoom_or_topic_type_class)
    Topic.all(:conditions => ["topic_type_id IN (?)", type.full_set.collect { |tt| tt.id }]).each { |t| t.destroy }
  else
    type = type_class.constantize.find_by_class_name(zoom_or_topic_type_class)
    type.class_name.constantize.destroy_all
  end
  type.send("#{type_class.underscore.to_sym}_to_field_mappings").destroy_all
  type.form_fields << create_extended_field(:label => 'Name', :multiple => false)
  if make_one_required
    type.required_form_fields << create_extended_field(:label => 'Hobbies', :multiple => true)
  else
    type.form_fields << create_extended_field(:label => 'Hobbies', :multiple => true)
  end
  type.reload
  mappings = type.send("#{type_class.underscore.to_sym}_to_field_mappings")[-2..-1] # select the last two
  [type, mappings]
end

# Populate some items with empty extended field data. Pass in the zoom class,
# mapping, and options hash (which is passed to the factory for item creation).
# It generated XML in the same format that we would get if we used the extended
# field library to generate the xml
def populate_empty_extended_field_data_for(zoom_class, mapping, options = {})
  ef_label = mapping.extended_field.label_for_params
  element_label = mapping.extended_field.multiple? ? "#{ef_label}_multiple" : ef_label

  ef_data = [nil, '']
  if mapping.extended_field.multiple?
    ef_data << "<#{element_label}><1><#{ef_label}></#{ef_label}></1></#{element_label}>"
    ef_data << "<#{element_label} xml_element_type='dc:element'><1><#{ef_label} xml_element_type='dc:element'></#{ef_label}></1></#{element_label}>"
    ef_data << "<#{element_label}><1><#{ef_label}></#{ef_label}></1><2><#{ef_label}></#{ef_label}></2></#{element_label}>"
    ef_data << "<#{element_label} xml_element_type='dc:element'><1><#{ef_label} xml_element_type='dc:element'></#{ef_label}></1><2><#{ef_label} xml_element_type='dc:element'></#{ef_label}></2></#{element_label}>"
  else
    ef_data << "<#{element_label}/>"
    ef_data << "<#{element_label} xml_element_type='dc:subject'/>"
    ef_data << "<#{element_label}></#{element_label}>"
    ef_data << "<#{element_label} xml_element_type='dc:subject'></#{element_label}>"
  end

  populate_extended_field_data_for(zoom_class, ef_data, options)
end

# Populate some items with filled in extended field data. Pass in the zoom
# class, mapping, and options hash (which is passed to the factory for item
# creation). It generated XML in the same format that we would get if we used
# the extended field library to generate the xml
def populate_filled_in_extended_field_data_for(zoom_class, mapping, options = {})
  ef_label = mapping.extended_field.label_for_params
  element_label = mapping.extended_field.multiple? ? "#{ef_label}_multiple" : ef_label

  ef_data = [nil, '']
  if mapping.extended_field.multiple?
    ef_data << "<#{element_label}><1><#{ef_label}>value</#{ef_label}></1></#{element_label}>"
    ef_data << "<#{element_label} xml_element_type='dc:element'><1><#{ef_label} xml_element_type='dc:element'>value</#{ef_label}></1></#{element_label}>"
  else
    ef_data << "<#{element_label}>value</#{element_label}>"
    ef_data << "<#{element_label} xml_element_type='dc:subject'>value</#{element_label}>"
  end

  populate_extended_field_data_for(zoom_class, ef_data, options)
end

# Loops over item privacy and extended field data and create an item. Pass in
# the zoom class of the item to be made, the ef_data array, and an options hash
# passed to the factory on item creation.
def populate_extended_field_data_for(zoom_class, ef_data, options = {})
  [true, false].each do |is_private|
    Factory(zoom_class.tableize.singularize.to_sym, { :extended_content => ef_data.join, :private => is_private }.merge(options))
  end
end

def item_for(zoom_class, options = {})
  if ATTACHABLE_CLASSES.include?(zoom_class)
    file_data = case zoom_class
                when 'AudioRecording'
                  fixture_file_upload('/files/Sin1000Hz.mp3', 'audio/mpeg')
                when 'Document'
                  fixture_file_upload('/files/test.pdf', 'application/pdf')
                when 'Video'
                  fixture_file_upload('/files/teststrip.mpg', 'video/mpeg')
                end
  end

  options = { :title => 'Item', :description => 'Description', :basket_id => 1 }.merge(options)
  options[:topic_type_id] = options[:topic_type_id] || 1 if zoom_class == 'Topic'
  options[:url] = options[:url] || "http://google.co.nz/#{rand}" if zoom_class == 'WebLink'
  options[:uploaded_data] = file_data if (ATTACHABLE_CLASSES - ['StillImage']).include?(zoom_class)
  if zoom_class == 'Comment' && options[:commentable_type].blank? && options[:commentable_id].blank?
    commentable_topic = Topic.create(:title => 'Commented Topic', :topic_type_id => 1, :basket_id => 1)
    options.merge!(:commentable_type => 'Topic', :commentable_id => commentable_topic.id)
  end

  @item = zoom_class.constantize.create! options

  user = User.find(1)
  @item.creators << user
  @item
end
