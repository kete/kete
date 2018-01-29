require File.dirname(__FILE__) + '/../test_helper'

class BasketTest < ActiveSupport::TestCase
  # fixtures preloaded

  def setup
    @base_class = "Basket"

    # hash of params to create new instance of model, e.g. {:name => 'Test Model', :description => 'Dummy'}
    @new_model = { :name => 'test basket', :private_default => false, :file_private_default => false }
    @req_attr_names = %w(name)
    # name of fields that must be present, e.g. %(name description)
    @duplicate_attr_names = %w() # name of fields that cannot be a duplicate, e.g. %(name description)
  end

  # load in sets of tests and helper methods
  include KeteTestUnitHelper

  # only include in basket and audio unit tests
  include FriendlyUrlsTestUnitHelper

  # test our polymorphic association with our profiles
  should have_many(:profile_mappings).dependent(:destroy)
  should have_many(:profiles).through(:profile_mappings)

  context "The Basket class" do
    should "have valid an array of relevant forms with human readable labels" do
      options_spec = [['Basket New or Edit', 'edit'],
                      ['Basket Appearance', 'appearance'],
                      ['Basket Homepage Options', 'homepage_options']]
      assert_equal Basket.forms_options, options_spec
    end
  end

  def test_before_save_urlify_name
    basket = Basket.new(@new_model.merge(:name => "something wicked this way comes"))
    assert_nil basket.urlified_name, "#{@base_class}.urlified_name shouldn't have a value yet."
    basket.save!
    basket.reload
    assert_equal "something_wicked_this_way_comes", basket.urlified_name, "#{@base_class}.urlified_name should match this."
  end

  def test_before_update_register_redirect_if_necessary
    basket = Basket.create(@new_model.merge(:name => "foo"))

    basket.name = "bar"

    basket.save!

    assert_not_nil RedirectRegistration.find(:first,
                                             :conditions => {
                                               :source_url_pattern => '/foo/',
                                               :target_url_pattern => '/bar/'
                                             })
  end

  def test_update_index_topic
    basket = Basket.create(@new_model.merge(:name => "something wicked this way comes"))
    assert_nil basket.index_topic, "#{@base_class}.index_topic shouldn't have a value yet."
    index_topic = Topic.create!(:title => 'test topic', :basket => basket, :topic_type => TopicType.find(:first))
    basket.update_index_topic(index_topic)
    basket.reload
    assert_equal index_topic, basket.index_topic, "#{@base_class}.index_topic should match this."
  end

  def test_update_index_topic_destroy
    basket = Basket.create(@new_model.merge(:name => "something wicked this way comes"))
    index_topic = Topic.create!(:title => 'test topic', :basket => basket, :topic_type => TopicType.find(:first))
    basket.update_index_topic(index_topic)
    basket.reload
    basket.update_index_topic('destroy')
    basket.reload
    assert_nil basket.index_topic, "#{@base_class}.index_topic should have been made nil."
  end

  def test_basket_defaults
    basket = Basket.new
    assert basket.new_record?

    assert_equal false, basket.private_default?
    assert_equal false, basket.file_private_default?
    assert_equal false, basket.allow_non_member_comments?
  end

  def test_should_set_basket_sort_defaults
    basket = Basket.create(@new_model)
    basket.settings[:sort_order_default] = 'date'
    basket.settings[:sort_direction_reversed_default] = 'reverse'
    assert_equal 'date', basket.settings[:sort_order_default]
    assert_equal 'reverse', basket.settings[:sort_direction_reversed_default]
  end

  def test_should_use_user_defined_sort_settings_over_baskets
    basket = Basket.create(@new_model)
    basket.settings[:sort_order_default] = 'date'
    basket.settings[:sort_direction_reversed_default] = 'reverse'

    # set some nessesary variables
    params = {}
    sort_type = basket.settings[:sort_order_default]
    sort_direction = basket.settings[:sort_direction_reversed_default]

    params[:sort_type] = ''
    params[:sort_direction] = ''
    # the following two lines were taken from search_controller.rb
    search_sort_type_1 = params[:sort_type].blank? and !sort_type.blank? ? sort_type : params[:sort_type]
    search_sort_direction_1 = params[:sort_type].blank? and !sort_direction.blank? ? sort_direction : params[:sort_direction]

    params[:sort_type] = 'last_modified'
    params[:sort_direction] = ''
    # the following two lines were taken from search_controller.rb
    search_sort_type_2 = params[:sort_type].blank? and !sort_type.blank? ? sort_type : params[:sort_type]
    search_sort_direction_2 = params[:sort_type].blank? and !sort_direction.blank? ? sort_direction : params[:sort_direction]

    assert_equal 'date', search_sort_type_1
    assert_equal 'reverse', search_sort_direction_1

    assert_equal 'last_modified', search_sort_type_2
    assert_equal '', search_sort_direction_2
  end

  def test_should_set_basket_menu_sort_defaults
    basket = Basket.create(@new_model)
    basket.settings[:side_menu_ordering_of_topics] = 'alphabetical'
    basket.settings[:side_menu_direction_of_topics] = 'reverse'
    assert_equal 'alphabetical', basket.settings[:side_menu_ordering_of_topics]
    assert_equal 'reverse', basket.settings[:side_menu_direction_of_topics]
  end

  # James - 2008-12-10
  # Ensure normal baskets can be deleted
  def test_baskets_other_than_site_can_be_deleted
    basket = Basket.find(2)
    basket.destroy

    assert_raises(ActiveRecord::RecordNotFound) { Basket.find(2) }
  end

  # Ensure that the site basket cannot be deleted
  def test_site_basket_cannot_be_deleted
    basket = Basket.find(1)
    assert_raises(RuntimeError) { basket.destroy }
    assert_equal basket, Basket.find(1)
  end

  # Ensure that site basket cannot be deleted after rename
  def test_site_basket_cannot_be_deleted_after_rename
    basket = Basket.find(1)
    assert_equal "site", basket.urlified_name

    basket.update_attributes(:name => "Another name")
    assert_equal "another_name", basket.urlified_name

    assert_raises(RuntimeError) { basket.destroy }
    assert_equal basket, Basket.find(1)
  end

  def test_allows_contact_with_inheritance
    site_basket = Basket.first # site
    site_basket.settings[:allow_basket_admin_contact] = true
    assert_equal true, site_basket.allows_contact_with_inheritance?

    about_basket = Basket.find_by_id(3) # about

    about_basket.settings[:allow_basket_admin_contact] = true
    assert_equal true, about_basket.allows_contact_with_inheritance?

    about_basket.settings[:allow_basket_admin_contact] = false
    assert_equal false, about_basket.allows_contact_with_inheritance?

    about_basket.settings[:allow_basket_admin_contact] = nil
    assert_equal true, about_basket.allows_contact_with_inheritance?
  end

  def test_memberlist_policy_or_default
    about_basket = Basket.find_by_id(3) # about
    result = about_basket.memberlist_policy_or_default
    expected = "<option value=\"all users\">All users</option><option value=\"logged in\">Logged in user</option><option value=\"at least member\">Basket member</option><option value=\"at least moderator\">Basket moderator</option><option value=\"at least admin\" selected=\"selected\">Basket admin</option>"
    assert_equal expected, result
  end

  def test_import_archive_set_policy_or_default
    about_basket = Basket.find_by_id(3) # about
    expected = "<option value=\"at least member\">Basket member</option><option value=\"at least moderator\">Basket moderator</option><option value=\"at least admin\" selected=\"selected\">Basket admin</option>"
    assert_equal expected, about_basket.import_archive_set_policy_or_default
  end

  def test_import_archive_set_policy_with_inheritance
    site_basket = Basket.find(1) # site
    about_basket = Basket.find(3) # about

    # it should have a default
    site_basket.settings[:import_archive_set_policy] = nil
    about_basket.settings[:import_archive_set_policy] = nil
    assert_equal 'at least admin', about_basket.import_archive_set_policy_with_inheritance

    # it should inherit from site basket
    site_basket.settings[:import_archive_set_policy] = 'at least moderator'
    assert_equal 'at least moderator', about_basket.import_archive_set_policy_with_inheritance

    # finally, it should use its own value
    about_basket.settings[:import_archive_set_policy] = 'at least member'
    assert_equal 'at least member', about_basket.import_archive_set_policy_with_inheritance
  end

  def test_allows_join_requests_with_inheritance
    site_basket = Basket.site_basket # site
    about_basket = Basket.about_basket # about

    site_basket.settings[:basket_join_policy] = 'open'
    assert_equal 'open', site_basket.join_policy_with_inheritance
    assert_equal true, site_basket.allows_join_requests_with_inheritance?

    about_basket.settings[:basket_join_policy] = 'open'
    assert_equal 'open', about_basket.join_policy_with_inheritance
    assert_equal true, about_basket.allows_join_requests_with_inheritance?

    about_basket.settings[:basket_join_policy] = 'request'
    assert_equal 'request', about_basket.join_policy_with_inheritance
    assert_equal true, about_basket.allows_join_requests_with_inheritance?

    about_basket.settings[:basket_join_policy] = 'closed'
    assert_equal 'closed', about_basket.join_policy_with_inheritance
    assert_equal false, about_basket.allows_join_requests_with_inheritance?

    about_basket.settings[:basket_join_policy] = nil
    assert_equal 'open', about_basket.join_policy_with_inheritance
    assert_equal true, about_basket.allows_join_requests_with_inheritance?
  end

  def test_should_get_administrator_instances
    # test it catches site_admin
    basket = Basket.first # site
    administrators = basket.administrators
    assert_equal 1, administrators.size
    assert_kind_of User, administrators.first

    # test it catches admin
    basket = Basket.last # admin
    administrators = basket.administrators
    assert_equal 1, administrators.size
    assert_kind_of User, administrators.first
  end

  def test_basket_should_have_a_creator
    basket = Basket.first
    assert_kind_of User, basket.creator
  end

  # TODO: tag_counts_array
  # TODO: index_page_order_tags_by

  context "The users_to_notify_of_private_item method" do
    should "work with various settings" do
      basket = create_new_basket :name => 'Notify Basket'

      # setup basket admin
      neil = create_new_user :login => 'neil'
      neil.has_role('admin', basket)
      # setup basket moderator
      jack = create_new_user :login => 'jack'
      jack.has_role('moderator', basket)
      # setup basket member
      nancy = create_new_user :login => 'nancy'
      nancy.has_role('member', basket)

      basket.settings[:private_item_notification] = 'at least admin'
      assert_equal 1, basket.users_to_notify_of_private_item.size
      assert_equal %w{neil}, basket.users_to_notify_of_private_item.collect { |u| u.login }

      basket.settings[:private_item_notification] = 'at least moderator'
      assert_equal 2, basket.users_to_notify_of_private_item.size
      assert_equal %w{neil jack}, basket.users_to_notify_of_private_item.collect { |u| u.login }

      basket.settings[:private_item_notification] = 'at least member'
      assert_equal 3, basket.users_to_notify_of_private_item.size
      assert_equal %w{neil jack nancy}, basket.users_to_notify_of_private_item.collect { |u| u.login }

      basket.settings[:private_item_notification] = 'do_not_email'
      assert_equal 0, basket.users_to_notify_of_private_item.size
      assert_equal [], basket.users_to_notify_of_private_item.collect { |u| u.login }
    end
  end

  context "The moderators_or_next_in_line method" do
    should "return the correct users to notify" do
      site_basket = Basket.site_basket
      basket = create_new_basket :name => 'Moderated Basket'

      set_constant(:NOTIFY_SITE_ADMINS_OF_FLAGGINGS, false)

      # site admin should already exist at this point
      assert_equal 1, basket.moderators_or_next_in_line.size
      assert_equal 'admin', basket.moderators_or_next_in_line.first.login

      neil = create_new_user :login => 'neil'
      neil.has_role('admin', site_basket)
      assert_equal 1, basket.moderators_or_next_in_line.size
      assert_equal 'neil', basket.moderators_or_next_in_line.first.login

      sarah = create_new_user :login => 'sarah'
      sarah.has_role('admin', basket)
      assert_equal 1, basket.moderators_or_next_in_line.size
      assert_equal 'sarah', basket.moderators_or_next_in_line.first.login

      jack = create_new_user :login => 'jack'
      jack.has_role('moderator', basket)
      assert_equal 1, basket.moderators_or_next_in_line.size
      assert_equal 'jack', basket.moderators_or_next_in_line.first.login

      set_constant(:NOTIFY_SITE_ADMINS_OF_FLAGGINGS, true)

      assert_equal 2, basket.moderators_or_next_in_line.size
      assert_equal 'jack', basket.moderators_or_next_in_line.first.login
      assert_equal 'admin', basket.moderators_or_next_in_line.last.login
    end
  end
end
