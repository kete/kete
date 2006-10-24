require File.dirname(__FILE__) + '/../test_helper'
require 'topics_controller'

# Re-raise errors caught by the controller.
class TopicsController; def rescue_action(e) raise e end; end

class TopicsControllerTest < Test::Unit::TestCase
  fixtures :topics

	NEW_TOPIC = {}	# e.g. {:name => 'Test Topic', :description => 'Dummy'}
	REDIRECT_TO_MAIN = {:action => 'list'} # put hash or string redirection that you normally expect

	def setup
		@controller = TopicsController.new
		@request    = ActionController::TestRequest.new
		@response   = ActionController::TestResponse.new
		# Retrieve fixtures via their name
		# @first = topics(:first)
		@first = Topic.find_first
	end

  def test_component
    get :component
    assert_response :success
    assert_template 'topics/component'
    topics = check_attrs(%w(topics))
    assert_equal Topic.find(:all).length, topics.length, "Incorrect number of topics shown"
  end

  def test_component_update
    get :component_update
    assert_response :redirect
    assert_redirected_to REDIRECT_TO_MAIN
  end

  def test_component_update_xhr
    xhr :get, :component_update
    assert_response :success
    assert_template 'topics/component'
    topics = check_attrs(%w(topics))
    assert_equal Topic.find(:all).length, topics.length, "Incorrect number of topics shown"
  end

  def test_create
  	topic_count = Topic.find(:all).length
    post :create, {:topic => NEW_TOPIC}
    topic, successful = check_attrs(%w(topic successful))
    assert successful, "Should be successful"
    assert_response :redirect
    assert_redirected_to REDIRECT_TO_MAIN
    assert_equal topic_count + 1, Topic.find(:all).length, "Expected an additional Topic"
  end

  def test_create_xhr
  	topic_count = Topic.find(:all).length
    xhr :post, :create, {:topic => NEW_TOPIC}
    topic, successful = check_attrs(%w(topic successful))
    assert successful, "Should be successful"
    assert_response :success
    assert_template 'create.rjs'
    assert_equal topic_count + 1, Topic.find(:all).length, "Expected an additional Topic"
  end

  def test_update
  	topic_count = Topic.find(:all).length
    post :update, {:id => @first.id, :topic => @first.attributes.merge(NEW_TOPIC)}
    topic, successful = check_attrs(%w(topic successful))
    assert successful, "Should be successful"
    topic.reload
   	NEW_TOPIC.each do |attr_name|
      assert_equal NEW_TOPIC[attr_name], topic.attributes[attr_name], "@topic.#{attr_name.to_s} incorrect"
    end
    assert_equal topic_count, Topic.find(:all).length, "Number of Topics should be the same"
    assert_response :redirect
    assert_redirected_to REDIRECT_TO_MAIN
  end

  def test_update_xhr
  	topic_count = Topic.find(:all).length
    xhr :post, :update, {:id => @first.id, :topic => @first.attributes.merge(NEW_TOPIC)}
    topic, successful = check_attrs(%w(topic successful))
    assert successful, "Should be successful"
    topic.reload
   	NEW_TOPIC.each do |attr_name|
      assert_equal NEW_TOPIC[attr_name], topic.attributes[attr_name], "@topic.#{attr_name.to_s} incorrect"
    end
    assert_equal topic_count, Topic.find(:all).length, "Number of Topics should be the same"
    assert_response :success
    assert_template 'update.rjs'
  end

  def test_destroy
  	topic_count = Topic.find(:all).length
    post :destroy, {:id => @first.id}
    assert_response :redirect
    assert_equal topic_count - 1, Topic.find(:all).length, "Number of Topics should be one less"
    assert_redirected_to REDIRECT_TO_MAIN
  end

  def test_destroy_xhr
  	topic_count = Topic.find(:all).length
    xhr :post, :destroy, {:id => @first.id}
    assert_response :success
    assert_equal topic_count - 1, Topic.find(:all).length, "Number of Topics should be one less"
    assert_template 'destroy.rjs'
  end

protected
	# Could be put in a Helper library and included at top of test class
  def check_attrs(attr_list)
    attrs = []
    attr_list.each do |attr_sym|
      attr = assigns(attr_sym.to_sym)
      assert_not_nil attr,       "Attribute @#{attr_sym} should not be nil"
      assert !attr.new_record?,  "Should have saved the @#{attr_sym} obj" if attr.class == ActiveRecord
      attrs << attr
    end
    attrs.length > 1 ? attrs : attrs[0]
  end
end
