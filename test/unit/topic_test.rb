require File.dirname(__FILE__) + '/../test_helper'

class TopicTest < Test::Unit::TestCase
  fixtures :topics

	NEW_TOPIC = {}	# e.g. {:name => 'Test Topic', :description => 'Dummy'}
	REQ_ATTR_NAMES 			 = %w( ) # name of fields that must be present, e.g. %(name description)
	DUPLICATE_ATTR_NAMES = %w( ) # name of fields that cannot be a duplicate, e.g. %(name description)

  def setup
    # Retrieve fixtures via their name
    # @first = topics(:first)
  end

  def test_raw_validation
    topic = Topic.new
    if REQ_ATTR_NAMES.blank?
      assert topic.valid?, "Topic should be valid without initialisation parameters"
    else
      # If Topic has validation, then use the following:
      assert !topic.valid?, "Topic should not be valid without initialisation parameters"
      REQ_ATTR_NAMES.each {|attr_name| assert topic.errors.invalid?(attr_name.to_sym), "Should be an error message for :#{attr_name}"}
    end
  end

	def test_new
    topic = Topic.new(NEW_TOPIC)
    assert topic.valid?, "Topic should be valid"
   	NEW_TOPIC.each do |attr_name|
      assert_equal NEW_TOPIC[attr_name], topic.attributes[attr_name], "Topic.@#{attr_name.to_s} incorrect"
    end
 	end

	def test_validates_presence_of
   	REQ_ATTR_NAMES.each do |attr_name|
			tmp_topic = NEW_TOPIC.clone
			tmp_topic.delete attr_name.to_sym
			topic = Topic.new(tmp_topic)
			assert !topic.valid?, "Topic should be invalid, as @#{attr_name} is invalid"
    	assert topic.errors.invalid?(attr_name.to_sym), "Should be an error message for :#{attr_name}"
    end
 	end

	def test_duplicate
    current_topic = Topic.find_first
   	DUPLICATE_ATTR_NAMES.each do |attr_name|
   		topic = Topic.new(NEW_TOPIC.merge(attr_name.to_sym => current_topic[attr_name]))
			assert !topic.valid?, "Topic should be invalid, as @#{attr_name} is a duplicate"
    	assert topic.errors.invalid?(attr_name.to_sym), "Should be an error message for :#{attr_name}"
		end
	end
end

