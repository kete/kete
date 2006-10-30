require File.dirname(__FILE__) + '/../test_helper'

class WebLinkTest < Test::Unit::TestCase
  fixtures :web_links

	NEW_WEB_LINK = {}	# e.g. {:name => 'Test WebLink', :description => 'Dummy'}
	REQ_ATTR_NAMES 			 = %w( ) # name of fields that must be present, e.g. %(name description)
	DUPLICATE_ATTR_NAMES = %w( ) # name of fields that cannot be a duplicate, e.g. %(name description)

  def setup
    # Retrieve fixtures via their name
    # @first = web_links(:first)
  end

  def test_raw_validation
    web_link = WebLink.new
    if REQ_ATTR_NAMES.blank?
      assert web_link.valid?, "WebLink should be valid without initialisation parameters"
    else
      # If WebLink has validation, then use the following:
      assert !web_link.valid?, "WebLink should not be valid without initialisation parameters"
      REQ_ATTR_NAMES.each {|attr_name| assert web_link.errors.invalid?(attr_name.to_sym), "Should be an error message for :#{attr_name}"}
    end
  end

	def test_new
    web_link = WebLink.new(NEW_WEB_LINK)
    assert web_link.valid?, "WebLink should be valid"
   	NEW_WEB_LINK.each do |attr_name|
      assert_equal NEW_WEB_LINK[attr_name], web_link.attributes[attr_name], "WebLink.@#{attr_name.to_s} incorrect"
    end
 	end

	def test_validates_presence_of
   	REQ_ATTR_NAMES.each do |attr_name|
			tmp_web_link = NEW_WEB_LINK.clone
			tmp_web_link.delete attr_name.to_sym
			web_link = WebLink.new(tmp_web_link)
			assert !web_link.valid?, "WebLink should be invalid, as @#{attr_name} is invalid"
    	assert web_link.errors.invalid?(attr_name.to_sym), "Should be an error message for :#{attr_name}"
    end
 	end

	def test_duplicate
    current_web_link = WebLink.find_first
   	DUPLICATE_ATTR_NAMES.each do |attr_name|
   		web_link = WebLink.new(NEW_WEB_LINK.merge(attr_name.to_sym => current_web_link[attr_name]))
			assert !web_link.valid?, "WebLink should be invalid, as @#{attr_name} is a duplicate"
    	assert web_link.errors.invalid?(attr_name.to_sym), "Should be an error message for :#{attr_name}"
		end
	end
end

