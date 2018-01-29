require File.dirname(__FILE__) + '/../test_helper'

class CommentsControllerTest < ActionController::TestCase
  include KeteTestFunctionalHelper

  def setup
    @base_class = "Comments"

    @new_basket_model = {
      :name                 => 'test basket',
      :private_default      => false,
      :file_private_default => false
    }

    @new_comment_model = {
      :title            => 'test comment',
      :description      => 'test',
      :basket_id        => nil, # Replaced during test
      :commentable_id   => 1,
      :commentable_type => 'Topic',
      :commentable_private => "false"
    }

    @new_user_model = {
      :login => 'quire',
      :email => 'quire@example.com',
      :password => 'quire',
      :password_confirmation => 'quire',
      :agree_to_terms => '1',
      :security_code => 'test',
      :security_code_confirmation => 'test',
      :locale => 'en'
    }

    @closed_basket  = Basket.create!(@new_basket_model.merge(:allow_non_member_comments => false, :name => "closed basket", :status => 'approved', :creator_id => 1))
    @open_basket    = Basket.create!(@new_basket_model.merge(:allow_non_member_comments => true, :name => "open basket", :status => 'approved', :creator_id => 1))
    @non_member_user = User.create!(@new_user_model)
    @member_user = User.create!(@new_user_model.merge(:login => 'doug', :email => 'doug@example.com'))
    @member_user.has_role('member', @closed_basket)
  end

  def test_baskets_set_up
    [@closed_basket, @open_basket].each do |basket|
      assert basket.valid?
      assert basket.respond_to?(:allow_non_member_comments)
      assert_not_nil basket.allow_non_member_comments
    end
  end

  def test_users_set_up
    [@non_member_user, @member_user].each do |user|
      assert user.valid?
    end
    assert_equal true, @member_user.has_role?('member', @closed_basket)
  end

  def test_protected_from_non_member_comments_not_logged_in
    get :new, :urlified_name => "closed_basket", :commentable_id => 1, :commentable_type => "Topic", :commentable_private => "false"
    assert_response :redirect
    assert_redirected_to :urlified_name => "site", :controller => "account", :action => "login", :locale => :en
  end

  def test_protected_from_non_member_comments_non_member
    login_as(:quire)
    get :new, :urlified_name => "closed_basket", :commentable_id => 1, :commentable_type => "Topic", :commentable_private => "false"
    assert_response :redirect
    assert_redirected_to :urlified_name => 'closed_basket', :controller => "baskets", :action => "permission_denied", :locale => :en
  end

  def test_protected_allows_member_comments_from_member
    login_as(:doug)
    get :new, :urlified_name => "closed_basket", :commentable_id => 1, :commentable_type => "Topic", :commentable_private => "false"
    assert_response :success
    assert_template 'comments/new'
    assert_not_nil assigns(:comment)
  end

  def test_protected_from_non_member_comments_not_logged_in2
    get :new, :urlified_name => "open_basket", :commentable_id => 1, :commentable_type => "Topic", :commentable_private => "false"
    assert_response :redirect
    assert_redirected_to :urlified_name => 'site', :controller => "account", :action => "login", :locale => :en
  end

  def test_allow_non_member_comments_non_member
    login_as(:quire)
    get :new, :urlified_name => "open_basket", :commentable_id => 1, :commentable_type => "Topic", :commentable_private => "false"
    assert_response :success
    assert_template 'comments/new'
    assert_not_nil assigns(:comment)
  end

  def test_allow_non_member_comments_member
    login_as(:doug)
    get :new, :urlified_name => "open_basket", :commentable_id => 1, :commentable_type => "Topic", :commentable_private => "false"
    assert_response :success
    assert_template 'comments/new'
    assert_not_nil assigns(:comment)
  end

  def test_cannot_create_if_non_member_on_protected
    login_as(:quire)
    post :create, :urlified_name => "closed_basket", :comment => @new_comment_model
    assert_response :redirect
    assert_redirected_to :urlified_name => 'closed_basket', :controller => "baskets", :action => "permission_denied", :locale => :en
  end

  def test_can_create_if_non_member_on_unprotected
    login_as(:quire)
    post :create, :urlified_name => "open_basket", :comment => @new_comment_model.merge(:basket_id => @open_basket.id)
    assert assigns(:comment)
    assert_response :redirect
    assert_redirected_to :urlified_name => "about", :controller => "topics", :action => "show", :id => Topic.find(1), :locale => false, :anchor => assigns(:comment).to_anchor
  end
end
