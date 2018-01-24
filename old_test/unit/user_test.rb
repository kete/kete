require File.dirname(__FILE__) + '/../test_helper'

class UserTest < ActiveSupport::TestCase
  # Be sure to include AuthenticatedTestHelper in test/test_helper.rb instead.
  # Then, you can remove it from this and the functional test.
  include AuthenticatedTestHelper
  # fixtures preloaded

  def setup
    @users = User.find(:all)

    @base_class = "User"

    # hash of params to create new instance of model, e.g. {:name => 'Test Model', :description => 'Dummy'}
    @new_model = { :login => 'quire',
                   :email => 'quire@example.com',
                   :password => 'quire',
                   :password_confirmation => 'quire',
                   :agree_to_terms => '1',
                   :security_code => 'test',
                   :security_code_confirmation => 'test',
                   :locale => 'en' }

    # name of fields that must be present, e.g. %(name description)
    @req_attr_names = %w(login email agree_to_terms security_code password password_confirmation locale)
    # name of fields that cannot be a duplicate, e.g. %(name description)
    @duplicate_attr_names = %w(login)
  end

  # load in sets of tests and helper methods
  include KeteTestUnitHelper

  include ExtendedContentTestUnitHelper

  # TODO: a number of Kete custom methods not tested

  def test_should_create_user
    assert_difference('User.count') do
      user = create_user
      assert !user.new_record?, "#{user.errors.full_messages.to_sentence}"
    end
  end

  def test_should_require_login
    assert_no_difference('User.count') do
      u = create_user(:login => nil)
      assert u.errors.on(:login)
    end
  end

  def test_should_require_password
    assert_no_difference('User.count') do
      u = create_user(:password => nil)
      assert u.errors.on(:password)
    end
  end

  def test_should_require_password_confirmation
    assert_no_difference('User.count') do
      u = create_user(:password_confirmation => nil)
      assert u.errors.on(:password_confirmation)
    end
  end

  def test_should_require_email
    assert_no_difference('User.count') do
      u = create_user(:email => nil)
      assert u.errors.on(:email)
    end
  end

  def test_should_reset_password
    @users[0].update_attributes(:password => 'new password', :password_confirmation => 'new password')
    assert_equal @users[0], User.authenticate('admin', 'new password')
  end

  def test_should_not_rehash_password
    @users[0].update_attributes(:login => 'default2')
    assert_equal @users[0], User.authenticate('default2', 'test')
  end

  def test_should_authenticate_user
    assert_equal @users[0], User.authenticate('admin', 'test')
  end

  def test_should_set_remember_token
    @users[0].remember_me
    assert_not_nil @users[0].remember_token
    assert_not_nil @users[0].remember_token_expires_at
  end

  def test_should_unset_remember_token
    @users[0].remember_me
    assert_not_nil @users[0].remember_token
    @users[0].forget_me
    assert_nil @users[0].remember_token
  end

  # James Stradling <james@katipo.co.nz>, 2008-04-16
  # Previously we thought activation_code returned nil erroneously,
  # however this is intentional behaviour.
  # When the user record is saved, UserObserver automatically
  # activates the user, removing the activation_code
  def test_should_auto_activate_user
    user = create_user
    assert_nil user.activation_code

    # The user has been activated and the recently_activated?
    # flag unset by the observer.
    assert !user.recently_activated?
  end

  # James Stradling <james@katipo.co.nz>, 2008-04-16
  # Override constant setting so we can test
  # activation code is generated.
  def test_should_generate_activation_code
    Object.send(:remove_const, :REQUIRE_ACTIVATION)
    Object.send(:const_set, :REQUIRE_ACTIVATION, true)

    user = create_user
    assert_not_nil user.activation_code
  end

  def test_should_have_portraits
    user = create_user
    new_image_with_creator user
    UserPortraitRelation.new_portrait_for(user, @still_image)
    user.reload

    assert_not_nil user.user_portrait_relations
    assert_not_nil user.portraits
    assert_equal 1, user.portraits.size
    assert_kind_of StillImage, user.portraits.first
    assert_equal StillImage.last, user.portraits.first
  end

  def test_user_should_have_baskets
    user = User.first
    assert_equal 4, user.baskets.size
    assert_kind_of Basket, user.baskets.first
  end

  context "When dealing with display/resolved names, a user" do
    should "have the resolved name populated on save" do
      user = create_user({ :login => 'user100' })
      assert_equal 'user100', user.login
      assert_equal 'user100', user.resolved_name
      assert_nil user.display_name

      user = create_user({ :login => 'user101', :display_name => 'User 101' })
      assert_equal 'user101', user.login
      assert_equal 'User 101', user.resolved_name
      assert_equal 'User 101', user.display_name
    end

    should "have resolved name accessible through user_name" do
      user = create_user({ :login => 'user102', :display_name => 'User 102' })
      assert_equal 'User 102', user.resolved_name
      assert_equal 'User 102', user.user_name
    end
  end

  context "After a site is configured there" do
    should "be an anonymous user account" do
      assert User.find_by_login('anonymous')
    end
  end

  context "A user" do
    should "be able to be tested whether the user is anonymous" do
      assert !User.first.anonymous?
      assert User.find_by_login('anonymous').anonymous?
    end

    should "have a virtual attribute for website that is only available to anonymous user" do
      website = 'http://kete.net.nz'

      non_anonymous = User.first
      assert_nil non_anonymous.website

      non_anonymous.website = website
      assert_nil non_anonymous.website

      anonymous = User.find_by_login('anonymous')

      anonymous.website = website
      assert_equal anonymous.website, website
    end
  end

  protected

    def create_user(options = {})
      # Walter McGinnis, 2007-07-10
      # adding terms agreement and capcha vars
      User.create(@new_model.merge(options))
    end

    def new_model_attributes
      @@incremental_id ||= 0
      @@incremental_id = @@incremental_id + 1
      @new_model.merge(:login => 'test_login_' + @@incremental_id.to_s)
    end

    def new_image_with_creator(user)
      @still_image = StillImage.create(:title => 'test item',
                                       :basket_id => Basket.find(:first))
      @still_image.creator = user
      @still_image.save
    end
end
