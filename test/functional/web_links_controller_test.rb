require File.dirname(__FILE__) + '/../test_helper'
require 'web_links_controller'

# Re-raise errors caught by the controller.
class WebLinksController; def rescue_action(e) raise e end; end

class WebLinksControllerTest < Test::Unit::TestCase
  fixtures :web_links

	NEW_WEB_LINK = {}	# e.g. {:name => 'Test WebLink', :description => 'Dummy'}
	REDIRECT_TO_MAIN = {:action => 'list'} # put hash or string redirection that you normally expect

	def setup
		@controller = WebLinksController.new
		@request    = ActionController::TestRequest.new
		@response   = ActionController::TestResponse.new
		# Retrieve fixtures via their name
		# @first = web_links(:first)
		@first = WebLink.find_first
	end

  def test_component
    get :component
    assert_response :success
    assert_template 'web_links/component'
    web_links = check_attrs(%w(web_links))
    assert_equal WebLink.find(:all).length, web_links.length, "Incorrect number of web_links shown"
  end

  def test_component_update
    get :component_update
    assert_response :redirect
    assert_redirected_to REDIRECT_TO_MAIN
  end

  def test_component_update_xhr
    xhr :get, :component_update
    assert_response :success
    assert_template 'web_links/component'
    web_links = check_attrs(%w(web_links))
    assert_equal WebLink.find(:all).length, web_links.length, "Incorrect number of web_links shown"
  end

  def test_create
  	web_link_count = WebLink.find(:all).length
    post :create, {:web_link => NEW_WEB_LINK}
    web_link, successful = check_attrs(%w(web_link successful))
    assert successful, "Should be successful"
    assert_response :redirect
    assert_redirected_to REDIRECT_TO_MAIN
    assert_equal web_link_count + 1, WebLink.find(:all).length, "Expected an additional WebLink"
  end

  def test_create_xhr
  	web_link_count = WebLink.find(:all).length
    xhr :post, :create, {:web_link => NEW_WEB_LINK}
    web_link, successful = check_attrs(%w(web_link successful))
    assert successful, "Should be successful"
    assert_response :success
    assert_template 'create.rjs'
    assert_equal web_link_count + 1, WebLink.find(:all).length, "Expected an additional WebLink"
  end

  def test_update
  	web_link_count = WebLink.find(:all).length
    post :update, {:id => @first.id, :web_link => @first.attributes.merge(NEW_WEB_LINK)}
    web_link, successful = check_attrs(%w(web_link successful))
    assert successful, "Should be successful"
    web_link.reload
   	NEW_WEB_LINK.each do |attr_name|
      assert_equal NEW_WEB_LINK[attr_name], web_link.attributes[attr_name], "@web_link.#{attr_name.to_s} incorrect"
    end
    assert_equal web_link_count, WebLink.find(:all).length, "Number of WebLinks should be the same"
    assert_response :redirect
    assert_redirected_to REDIRECT_TO_MAIN
  end

  def test_update_xhr
  	web_link_count = WebLink.find(:all).length
    xhr :post, :update, {:id => @first.id, :web_link => @first.attributes.merge(NEW_WEB_LINK)}
    web_link, successful = check_attrs(%w(web_link successful))
    assert successful, "Should be successful"
    web_link.reload
   	NEW_WEB_LINK.each do |attr_name|
      assert_equal NEW_WEB_LINK[attr_name], web_link.attributes[attr_name], "@web_link.#{attr_name.to_s} incorrect"
    end
    assert_equal web_link_count, WebLink.find(:all).length, "Number of WebLinks should be the same"
    assert_response :success
    assert_template 'update.rjs'
  end

  def test_destroy
  	web_link_count = WebLink.find(:all).length
    post :destroy, {:id => @first.id}
    assert_response :redirect
    assert_equal web_link_count - 1, WebLink.find(:all).length, "Number of WebLinks should be one less"
    assert_redirected_to REDIRECT_TO_MAIN
  end

  def test_destroy_xhr
  	web_link_count = WebLink.find(:all).length
    xhr :post, :destroy, {:id => @first.id}
    assert_response :success
    assert_equal web_link_count - 1, WebLink.find(:all).length, "Number of WebLinks should be one less"
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
