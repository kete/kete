require File.dirname(__FILE__) + '/../test_helper'

class ContentItemRelationsTest < ActionController::TestCase
  tests SearchController

  include KeteTestFunctionalHelper

  def setup
    @base_class = "ContentItem"

    @class_names = %w[Topic StillImage AudioRecording Video WebLink Document]

    login_as(:admin)
  end

  def test_find_related_add
    for class_name in @class_names
      get :find_related, :urlified_name => "about", :relate_to_type => 'Topic', :relate_to_item => "1-about-kete", :function => "add", :related_class => class_name

      assert_not_nil assigns(:results)
      assert_equal "link", assigns(:next_action)

      assert_response :success
      assert_template 'search/related_form'
    end
  end

  def test_find_related_add_with_terms_no_results
    get :find_related, :urlified_name => "about", :relate_to_type => 'Topic', :relate_to_item => "1-about-kete", :function => "add", :related_class => "Topic", :search_terms => "The Art Of Computer Programming"

    assert_not_nil assigns(:results)
    assert_equal 0, assigns(:results).size

    assert_response :success
    assert_template 'search/related_form'
  end

  def test_find_related_remove_with_no_relationships
    for class_name in @class_names
      get :find_related, :urlified_name => "about", :relate_to_type => 'Topic', :relate_to_item => "1-about-kete", :function => "remove", :related_class => class_name

      assert_not_nil assigns(:results)
      assert_equal 0, assigns(:results).size

      assert_equal "unlink", assigns(:next_action)

      assert_response :success
      assert_template 'search/related_form'
    end
  end

  def test_find_related_remove_with_relationship
    # Add a test relationship
    add_relationship_between(Topic.find(1), Topic.find(2))
    assert_equal 1, Topic.find(1).related_topics.size
    assert_equal 2, Topic.find(1).related_topics.first.id

    get :find_related, :urlified_name => "about", :relate_to_type => 'Topic', :relate_to_item => "1-about-kete", :function => "remove", :related_class => "Topic"

    assert_not_nil assigns(:results)
    assert_equal 1, assigns(:results).size
    assert_equal 2, assigns(:results).first.id

    assert_response :success
    assert_template 'search/related_form'

    # Test the relationship from the other side.
    get :find_related, :urlified_name => "about", :relate_to_type => 'Topic', :relate_to_item => "2-house-rules", :function => "remove", :related_class => "Topic"

    assert_not_nil assigns(:results)
    assert_equal 1, assigns(:results).size
    assert_equal 1, assigns(:results).first.id

    assert_response :success
    assert_template 'search/related_form'
  end

  def test_find_related_restore
    for class_name in @class_names
      get :find_related, :urlified_name => "about", :relate_to_type => 'Topic', :relate_to_item => "1-about-kete", :function => "restore", :related_class => class_name

      assert_not_nil assigns(:results)
      assert_equal 0, assigns(:results).size
      assert_equal "link", assigns(:next_action)

      assert_response :success
      assert_template 'search/related_form'
    end
  end

  def test_find_related_restore_with_relationship
    # Add and delete a test relationship
    add_relationship_between(Topic.find(1), Topic.find(2))
    assert_equal 1, Topic.find(1).related_topics.size
    assert_equal 2, Topic.find(1).related_topics.first.id
    c = Topic.find(1).content_item_relations.first
    c.destroy
    assert_equal 0, Topic.find(1).related_topics.size

    get :find_related, :urlified_name => "about", :relate_to_type => 'Topic', :relate_to_item => "1-about-kete", :function => "restore", :related_class => "Topic"

    assert_not_nil assigns(:results)
    assert_equal 1, assigns(:results).size
    assert assigns(:results).first.is_a?(Topic)

    assert_equal "link", assigns(:next_action)

    assert_response :success
    assert_template 'search/related_form'
  end

  def test_link_without_items
    for class_name in @class_names
      get :link_related, :relate_to_type => 'Topic', :relate_to_item => "1-about-kete", :urlified_name => "about", :related_class => class_name, :item => {}

      assert_equal 1, assigns(:related_to_item).id
      assert_nil assigns(:successful)

      assert_response :redirect
      assert_redirected_to :controller => 'search', :action => 'find_related', :relate_to_type => 'Topic', :relate_to_item => "1-about-kete", :related_class => class_name, :function => 'remove'
    end
  end

  def test_link_with_items
    get :link_related, :relate_to_type => 'Topic', :relate_to_item => "1-about-kete", :urlified_name => "about", :related_class => "Topic", :item => { "2" => "true", "3" => "false" }

    assert_equal 1, assigns(:related_to_item).id
    assert_not_nil assigns(:successful)

    assert_equal 1, Topic.find(1).related_topics.size
    assert_equal 2, Topic.find(1).related_topics.first.id

    assert_equal "Successfully added item relationships", flash[:notice]

    assert_response :redirect
    assert_redirected_to :controller => 'search', :action => 'find_related', :relate_to_type => 'Topic', :relate_to_item => "1-about-kete", :related_class => "Topic", :function => 'remove'
  end

  def test_unlink_without_items
    for class_name in @class_names
      get :unlink_related, :relate_to_type => 'Topic', :relate_to_item => "1-about-kete", :urlified_name => "about", :related_class => class_name, :item => {}

      assert_equal 1, assigns(:related_to_item).id
      assert_nil assigns(:successful)

      assert_response :redirect
      assert_redirected_to :controller => 'search', :action => 'find_related', :relate_to_type => 'Topic', :relate_to_item => "1-about-kete", :related_class => class_name, :function => 'remove'
    end
  end

  def test_unlink_with_items
    # Add a test relationship
    add_relationship_between(Topic.find(3), Topic.find(4))
    assert_equal 1, Topic.find(3).related_topics.size
    assert_equal 4, Topic.find(3).related_topics.first.id

    get :unlink_related, :relate_to_type => 'Topic', :relate_to_item => "3-registration", :urlified_name => "about", :related_class => "Topic", :item => { "4" => "true" }

    assert_equal 3, assigns(:related_to_item).id
    assert_not_nil assigns(:successful)

    assert_equal 0, Topic.find(3).content_item_relations.size
    assert_equal "Successfully removed item relationships", flash[:notice]

    assert_response :redirect
    assert_redirected_to :controller => 'search', :action => 'find_related', :relate_to_type => 'Topic', :relate_to_item => "3-registration", :related_class => "Topic", :function => 'remove'
  end

  def test_link_with_deleted_items
    # Add and delete a test relationship
    add_relationship_between(Topic.find(1), Topic.find(2))
    assert_equal 1, Topic.find(1).related_topics.size
    assert_equal 2, Topic.find(1).related_topics.first.id
    c = Topic.find(1).content_item_relations.first
    relationship_id = c.id
    c.destroy
    assert_equal 0, Topic.find(1).related_topics.size

    get :link_related, :relate_to_type => 'Topic', :relate_to_item => "1-about-kete", :urlified_name => "about", :related_class => "Topic", :item => { "2" => "true", "3" => "false" }

    assert_equal 1, assigns(:related_to_item).id
    assert_not_nil assigns(:successful)

    assert_equal 1, Topic.find(1).related_topics.size
    assert_equal 2, Topic.find(1).related_topics.first.id
    assert_equal relationship_id, Topic.find(1).content_item_relations.first.id

    assert_equal "Successfully added item relationships", flash[:notice]

    assert_response :redirect
    assert_redirected_to :controller => 'search', :action => 'find_related', :relate_to_type => 'Topic', :relate_to_item => "1-about-kete", :related_class => "Topic", :function => 'remove'
  end

  protected

  def add_relationship_between(topic, item)
    ContentItemRelation.create(
      :topic_id => topic.id,
      :related_item_type => item.class.name,
      :related_item_id => item.id
    )
  end
end
