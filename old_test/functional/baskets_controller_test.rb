require File.dirname(__FILE__) + '/../test_helper'

class BasketsControllerTest < ActionController::TestCase
  include KeteTestFunctionalHelper

  def setup
    @base_class = "Basket"

    # hash of params to create new instance of model, e.g. {:name => 'Test Model', :description => 'Dummy'}
    @new_model = { :name => 'test basket', :private_default => false, :file_private_default => false, :status => 'requested', :creator_id => 1 }

    load_test_environment
    login_as(:admin)

    # hash of params to create new instance of model, e.g. {:name => 'Test Model', :description => 'Dummy'}
    @default_model = { :show_privacy_controls => nil,
                       :private_default => nil,
                       :file_private_default => nil,
                       :allow_non_member_comments => nil }
    @new_model =     { :name => 'Test Basket',
                       :show_privacy_controls => true,
                       :private_default => false,
                       :file_private_default => nil,
                       :allow_non_member_comments => true }
    @updated_model = { :show_privacy_controls => nil,
                       :private_default => true,
                       :file_private_default => false,
                       :allow_non_member_comments => nil }

    @req_attr_names = %w(name private_default file_private_default)
    # name of fields that must be present, e.g. %(name description)
    @duplicate_attr_names = %w( ) # name of fields that cannot be a duplicate, e.g. %(name description)
  end

  def test_redirect_to_basket_all
    get :show, :urlified_name => 'site'
    assert_redirect_to({ :urlified_name => 'site', :controller => 'search', :action => 'all', :controller_name_for_zoom_class => 'topics' })
  end

  def test_index_and_list
    get :index, index_path
    assert_redirect_to( :action => 'list' )

    get :list, index_path({ :action => 'list' })
    assert_viewing_template 'baskets/list'
    assert_var_assigned true
    assert_equal 4, assigns(:baskets).size
  end

  def test_new
    get :new, new_path
    assert_viewing_template 'baskets/new'
    assert_var_assigned
    assert_attributes_same_as @default_model
  end

  def test_create
    create_record
    assert_var_assigned
    assert_attributes_same_as @new_model
    assert_redirect_to( edit_path({ :urlified_name => assigns(:basket).urlified_name, :id => assigns(:basket).id }) )
    assert_equal 'Basket was successfully created.', flash[:notice]
  end

  def test_edit
    get :edit, edit_path
    assert_viewing_template 'baskets/edit'
    assert_var_assigned

    get :homepage_options, edit_path({ :action => 'homepage_options' })
    assert_viewing_template 'baskets/homepage_options'
    assert_var_assigned
  end

  def test_update
    update_record
    assert_var_assigned
    assert_attributes_same_as @updated_model
    assert_redirect_to '/site/'
    assert_equal 'Basket was successfully updated.', flash[:notice]
  end

  def test_destroy
    destroy_record({ :id => 4 }) # documentation basket
    assert_redirect_to '/'
    assert_equal 'Basket was successfully deleted.', flash[:notice]
  end

  def test_contact_restricted
    logout # logout to test contact form restricted
    # test contact form restricted to logged in members
    get :contact, :urlified_name => 'site'
    assert_response :redirect
    assert_redirected_to :urlified_name => 'site', :controller => 'account', :action => 'login', :locale => :en
  end

  def test_contact
    # test redirect when disabled
    get :contact, :urlified_name => 'site'
    assert_response :redirect
    assert_redirected_to '/'
    assert_equal "This contact form is not currently enabled.", flash[:notice]

    Basket.first.settings[:allow_basket_admin_contact] = true

    # test routes in place work
    get :contact, :urlified_name => 'site'
    assert_response :success
    assert_template 'email/contact'

    # test basic validation working
    post :send_email, :urlified_name => 'site'
    assert_response :success
    assert_template 'email/contact'
    assert_equal "Both subject and message must be filled in. Please try again.", flash[:error]

    # test successfull emailing
    post :send_email, :contact => { :subject => "test", :message => "test" }, :urlified_name => 'site'
    assert_response :redirect
    assert_redirected_to '/'
    assert_equal "Your email has been sent. You will receive the reply in your email box.", flash[:notice]
  end

  def test_basket_accessable_by_site_admin_when_status_not_approved
    basket = Basket.create(@new_model.merge({ :name => 'Test' }))
    get :list, :urlified_name => 'test', :controller => 'index_page', :action => 'index'
    assert_response :success
  end

  def test_basket_not_accessable_by_non_site_admin_when_status_not_approved
    logout
    basket = Basket.create(@new_model.merge({ :name => 'Test' }))
    get :list, :urlified_name => 'test', :controller => 'index_page', :action => 'index'
    assert_response :redirect
    assert_redirected_to "/site"
    assert_equal 'The basket Test is not approved for public viewing', flash[:error]
  end

  def test_basket_accessable_by_site_admin_when_approved
    basket = Basket.create(@new_model.merge({ :name => 'Test', :status => 'approved' }))
    get :list, :urlified_name => 'test', :controller => 'index_page', :action => 'index'
    assert_response :success
  end

  def test_basket_accessable_by_non_site_admin_when_approved
    logout
    basket = Basket.create(@new_model.merge({ :name => 'Test', :status => 'approved' }))
    get :list, :urlified_name => 'test', :controller => 'index_page', :action => 'index'
    assert_response :success
  end

  def test_basket_creation_only_accessable_to_site_admin_when_closed
    set_constant("BASKET_CREATION_POLICY", 'closed')
    assert_equal 'closed', BASKET_CREATION_POLICY
    get :new, :urlified_name => 'site', :controller => 'baskets', :action => 'new'
    assert_response :success
  end

  def test_basket_creation_not_accessable_to_non_site_admin_when_closed
    logout
    set_constant("BASKET_CREATION_POLICY", 'closed')
    assert_equal 'closed', BASKET_CREATION_POLICY
    get :new, :urlified_name => 'site', :controller => 'baskets', :action => 'new'
    assert_response :redirect
    assert_redirected_to :urlified_name => 'site', :controller => 'account', :action => 'login', :locale => :en
  end

  def test_basket_creation_accessable_when_moderated_and_site_admin
    set_constant("BASKET_CREATION_POLICY", 'request')
    assert_equal 'request', BASKET_CREATION_POLICY
    get :new, :urlified_name => 'site', :controller => 'baskets', :action => 'new'
    assert_response :success
  end

  def test_basket_creation_accessable_when_moderated_and_logged_in
    Factory(:user)
    login_as(:joe)
    set_constant("BASKET_CREATION_POLICY", 'request')
    assert_equal 'request', BASKET_CREATION_POLICY
    get :new, :urlified_name => 'site', :controller => 'baskets', :action => 'new'
    assert_response :success
  end

  def test_basket_creation_not_accessable_when_moderated_and_logged_out
    logout
    set_constant("BASKET_CREATION_POLICY", 'request')
    assert_equal 'request', BASKET_CREATION_POLICY
    get :new, :urlified_name => 'site', :controller => 'baskets', :action => 'new'
    assert_response :redirect
    assert_redirected_to :urlified_name => 'site', :controller => 'account', :action => 'login', :locale => :en
  end

  def test_basket_instant_approval_for_site_admin_even_if_moderation_on
    set_constant("BASKET_CREATION_POLICY", 'request')
    assert_equal 'request', BASKET_CREATION_POLICY
    post :create, :basket => @new_model, :urlified_name => 'site'
    assert_response :redirect
    assert_redirected_to :controller => 'baskets', :action => 'edit', :id => assigns(:basket).id, :urlified_name => assigns(:basket).urlified_name
    assert_equal 'approved', assigns(:basket).status
    assert_equal 'Basket was successfully created.', flash[:notice]
  end

  def test_basket_needing_moderation_after_creation_not_accessible_by_non_site_admin
    Factory(:user)
    login_as(:joe)
    set_constant("BASKET_CREATION_POLICY", 'request')
    assert_equal 'request', BASKET_CREATION_POLICY
    post :create, :basket => @new_model.merge({ :name => 'testing' }), :urlified_name => 'site'
    assert_response :redirect
    assert_redirected_to "/site"
    assert_equal 'Basket will now be reviewed, and you\'ll be notified of the outcome.', flash[:notice]
  end

  def test_basket_should_assign_creator
    post :create, :basket => @new_model, :urlified_name => 'site'
    assert_response :redirect
    assert_redirected_to :controller => 'baskets', :action => 'edit', :id => assigns(:basket).id, :urlified_name => assigns(:basket).urlified_name
    assert_kind_of User, assigns(:basket).creator
  end

  def test_listing_type_only_accessable_by_site_admin
    get :list, :urlified_name => 'site', :controller => 'baskets', :action => 'list', :type => 'requested'
    assert_response :success
    assert_not_nil assigns(:listing_type)
    assert_equal 'requested', assigns(:listing_type)
  end

  def test_listing_type_not_accessable_by_non_site_admin
    logout
    get :list, :urlified_name => 'site', :controller => 'baskets', :action => 'list', :type => 'requested'
    assert_response :success
    assert_not_nil assigns(:listing_type)
    assert_equal 'approved', assigns(:listing_type)
  end

  def test_rss_feed_accessible_logged_out
    logout
    get :rss, :urlified_name => 'site', :controller => 'baskets', :action => 'rss'
    assert_response :success
    assert_not_nil(:baskets)
  end

  def test_rss_feed_accessible_logged_in
    login_as(:admin)
    get :rss, :urlified_name => 'site', :controller => 'baskets', :action => 'rss'
    assert_response :success
    assert_not_nil(:baskets)
  end

  context "When basket profile(s) are available" do
    setup do
      @rules = {
        'edit' => {
          'rule_type' => 'some',
          'allowed' => ['show_privacy_controls'],
          'values' => {
            'show_privacy_controls' => false,
            'private_default' => false
          }
        }
      }
      @profile = Factory(:profile, :rules => @rules)
      set_constant("BASKET_CREATION_POLICY", 'open')
    end

    should "show basket form when only one profile exists" do
      get :new, :urlified_name => 'site'
      assert_response :success
      assert_not_nil(:template)
      title = assigns(:template).instance_variable_get(:@title)
      assert_equal 'New basket', title
    end

    should "show the profile selection form when more than one profile exists" do
      @profile2 = Factory(:profile)
      get :new, :urlified_name => 'site'
      assert_response :success
      assert_not_nil(:template)
      title = assigns(:template).instance_variable_get(:@title)
      assert_equal 'Choose Basket Profile', title
    end

    should "have form type set" do
      get :new, :urlified_name => 'site', :basket_profile => @profile.id
      assert_response :success
      assert_not_nil(:form_type)
      assert_equal :edit, assigns(:form_type)
    end

    should "have profile rules instance var available" do
      get :new, :urlified_name => 'site', :basket_profile => @profile.id
      assert_response :success
      assert_not_nil(:profile_rules)
      assert_equal @rules, assigns(:profile_rules)
    end

    should "alter the basket object to set some initial values" do
      get :new, :urlified_name => 'site', :basket_profile => @profile.id
      assert_response :success
      assert_not_nil(:basket)
      assert_equal false, assigns(:basket).show_privacy_controls
    end

    should "validate and replace values that shouldn't be there, but leave valid values, if the user is a non site admin" do
      Factory(:user)
      login_as(:joe)
      post :create, :urlified_name => 'site', :basket_profile => @profile.id, :basket => {
        :show_privacy_controls => true,
        :private_default => true,
        :file_private_default => true
      }
      assert_response :success
      assert_not_nil(:basket)
      assert_equal true, assigns(:basket).show_privacy_controls
      assert_equal false, assigns(:basket).private_default
      assert_equal nil, assigns(:basket).file_private_default
    end

    should "not validate and replace values if the current user is a site admin" do
      post :create, :urlified_name => 'site', :basket_profile => @profile.id, :basket => {
        :show_privacy_controls => true,
        :private_default => true,
        :file_private_default => true
      }
      assert_response :success
      assert_not_nil(:basket)
      assert_equal true, assigns(:basket).show_privacy_controls
      assert_equal true, assigns(:basket).private_default
      assert_equal true, assigns(:basket).file_private_default
    end
  end

  context "When a basket has a profile" do
    setup do
      @rules = {
        'edit' => {
          'rule_type' => 'some',
          'allowed' => ['show_privacy_controls', 'allow_non_member_comments'],
          'values' => {
            'show_privacy_controls' => false,
            'private_default' => false
          }
        }
      }
      @profile = Factory(:profile, :rules => @rules)

      @basket = Factory(:basket, :allow_non_member_comments => false)
      @basket.profiles << @profile

      set_constant("BASKET_CREATION_POLICY", 'open')
    end

    should "have form type set" do
      get :edit, :urlified_name => @basket.urlified_name, :id => @basket
      assert_response :success
      assert_not_nil(:form_type)
      assert_equal :edit, assigns(:form_type)
    end

    should "have profile rules instance var available" do
      get :edit, :urlified_name => @basket.urlified_name, :id => @basket
      assert_response :success
      assert_not_nil(:profile_rules)
      assert_equal @rules, assigns(:profile_rules)
    end

    should "not change values of existing basket settings when first editing" do
      get :edit, :urlified_name => @basket.urlified_name, :id => @basket
      assert_response :success
      assert_not_nil(:basket)
      assert_equal false, assigns(:basket).allow_non_member_comments
    end

    should "change values of existing basket settings after user submitting" do
      post :update, :urlified_name => @basket.urlified_name, :id => @basket, :basket => {
        :allow_non_member_comments => true
      }
      assert_response :redirect
      assert_equal 'Basket was successfully updated.', flash[:notice]
      get :edit, :urlified_name => @basket.urlified_name, :id => @basket
      assert_not_nil(:basket)
      assert_equal true, assigns(:basket).allow_non_member_comments
    end

    # Commented out because only site admins can edit baskets at this point
    #
    # should "validate and replace values that shouldn't be there, but leave valid values, if the user is a non site admin" do
    #   Factory(:user)
    #   login_as(:joe)
    #   post :update, :urlified_name => @basket.urlified_name, :id => @basket, :basket => {
    #     :show_privacy_controls => true,
    #     :private_default => true,
    #     :file_private_default => true
    #   }
    #   assert_response :redirect
    #   assert_equal 'Basket was successfully updated.', flash[:notice]
    #   get :edit, :urlified_name => @basket.urlified_name, :id => @basket
    #   assert_not_nil(:basket)
    #   assert_equal true, assigns(:basket).show_privacy_controls
    #   assert_equal false, assigns(:basket).private_default
    #   assert_equal nil, assigns(:basket).file_private_default
    # end

    should "not validate and replace values if the current user is a site admin" do
      post :update, :urlified_name => 'site', :basket_profile => @profile.id, :id => @basket, :basket => {
        :show_privacy_controls => true,
        :private_default => true,
        :file_private_default => true
      }
      assert_response :redirect
      assert_equal 'Basket was successfully updated.', flash[:notice]
      get :edit, :urlified_name => @basket.urlified_name, :id => @basket
      assert_not_nil(:basket)
      assert_equal true, assigns(:basket).show_privacy_controls
      assert_equal true, assigns(:basket).private_default
      assert_equal true, assigns(:basket).file_private_default
    end
  end

  private

  # Change a setting on a basket
  def change_setting_on_basket(basket_urlified_name, setting, value)
    @basket = Basket.find_by_urlified_name(basket_urlified_name)
    raise "#{basket_urlified_name} basket not found" if @basket.nil?
    @basket.settings[setting.to_sym] = value
  end
end
