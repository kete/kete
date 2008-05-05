require File.dirname(__FILE__) + '/../test_helper'

class UserTest < Test::Unit::TestCase
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
      :agree_to_terms => true,
      :security_code => 'test',
      :security_code_confirmation => 'test' }

    # name of fields that must be present, e.g. %(name description)
    @req_attr_names = %w(login email agree_to_terms security_code password password_confirmation)
    # name of fields that cannot be a duplicate, e.g. %(name description)
    @duplicate_attr_names = %w(login email)

  end

  # load in sets of tests and helper methods
  include KeteTestUnitHelper
  include ExtendedContentTestUnitHelper

  # TODO: a number of Kete custom methods not tested

  def test_should_create_user
    assert_difference User, :count do
      user = create_user
      assert !user.new_record?, "#{user.errors.full_messages.to_sentence}"
    end
  end

  def test_should_require_login
    assert_no_difference User, :count do
      u = create_user(:login => nil)
      assert u.errors.on(:login)
    end
  end

  def test_should_require_password
    assert_no_difference User, :count do
      u = create_user(:password => nil)
      assert u.errors.on(:password)
    end
  end

  def test_should_require_password_confirmation
    assert_no_difference User, :count do
      u = create_user(:password_confirmation => nil)
      assert u.errors.on(:password_confirmation)
    end
  end

  def test_should_require_email
    assert_no_difference User, :count do
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

  protected
    def create_user(options = {})
      # Walter McGinnis, 2007-07-10
      # adding terms agreement and capcha vars
      User.create(@new_model.merge(options))
    end
end
