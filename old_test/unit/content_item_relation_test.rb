require File.dirname(__FILE__) + '/../test_helper'

class ContentRelationTest < ActiveSupport::TestCase
  # fixtures preloaded

  # TODO: new_relation_to_topic

  def setup
    # Default attributes for new ContentItemRelation instance
    @new_model = {
      :position => nil,
      :topic => Topic.find(1),
      :related_item => Topic.find(2)
    }

    # Default attributes for new Topic instance
    @new_topic_model = {
      :title => 'test item',
      :topic_type => TopicType.find(:first),
      :basket => Basket.find(:first),
      :description => "Description text"
    }

    # Default attributes for new WebLink instance.
    @new_web_link_model = {
      :title => 'test item',
      :basket => Basket.find(:first),
      :url => "http://kete.net.nz/about/"
    }
  end

  def test_creates_new_relation
    assert_kind_of Topic, Topic.find(1)
    assert_kind_of Topic, Topic.find(2)

    assert ContentItemRelation.create(@new_model)

    [Topic.find(1), Topic.find(2)].each do |t|
      t.reload
    end

    assert_equal 1, Topic.find(1).related_topics.size
    assert_equal 1, Topic.find(2).related_topics.size

    assert_equal 1, Topic.find(1).content_item_relations.size
    assert_equal 1, Topic.find(2).child_content_item_relations.size

    assert_equal Topic.find(2), Topic.find(1).child_related_topics.first
    assert_equal Topic.find(1), Topic.find(2).parent_related_topics.first
  end

  def test_soft_delete
    c = ContentItemRelation.create(@new_model)
    assert_model_soft_deletes(c)
  end

  def test_deleting_one_side_of_the_relation_deletes_relation_from_related_item_side
    # Do the necessary set up
    assert_kind_of Topic, Topic.find(1)
    topic = Topic.create(@new_topic_model)
    assert_kind_of Topic, topic

    relation = ContentItemRelation.create(@new_model.merge(:related_item => topic))

    assert_equal Topic.find(1), relation.topic
    assert_equal topic, relation.related_item

    [Topic.find(1), topic].each do |t|
      t.reload
      assert_equal 1, t.related_topics.size
    end

    assert_equal topic, Topic.find(1).child_related_topics.first
    assert_equal Topic.find(1), topic.parent_related_topics.first

    topic.destroy

    assert_equal 0, Topic.find(1).content_item_relations.size
    assert_equal 0, Topic.find(1).child_related_topics.size
    assert_raises(ActiveRecord::RecordNotFound) { Topic.find(topic.id) }
    assert_raises(ActiveRecord::RecordNotFound) { ContentItemRelation.find(relation.id) }
    assert_raises(ActiveRecord::RecordNotFound) { ContentItemRelation::Deleted.find(relation.id) }
  end

  def test_deleting_one_side_of_the_relation_deletes_relation_from_related_item_side2
    # Do the necessary set up
    assert_kind_of Topic, Topic.find(1)
    web_link = WebLink.create(@new_web_link_model)
    assert_kind_of WebLink, web_link

    relation = ContentItemRelation.create(@new_model.merge(:related_item => web_link))

    assert_equal Topic.find(1), relation.topic
    assert_equal web_link, relation.related_item

    Topic.find(1).reload
    assert_equal 1, Topic.find(1).content_item_relations.size

    web_link.reload
    assert_equal 1, web_link.content_item_relations.size

    assert_equal web_link, Topic.find(1).web_links.first
    assert_equal Topic.find(1), web_link.topics.first

    web_link.destroy

    assert_equal 0, Topic.find(1).content_item_relations.size
    assert_equal 0, Topic.find(1).web_links.size
    assert_raises(ActiveRecord::RecordNotFound) { WebLink.find(web_link.id) }
    assert_raises(ActiveRecord::RecordNotFound) { ContentItemRelation.find(relation.id) }
    assert_raises(ActiveRecord::RecordNotFound) { ContentItemRelation::Deleted.find(relation.id) }
  end

  def test_deleting_one_side_of_the_relation_deletes_relation_from_topic_side
    # Do the necessary set up
    assert_kind_of Topic, Topic.find(1)
    topic = Topic.create(@new_topic_model)
    assert_kind_of Topic, topic

    relation = ContentItemRelation.create(@new_model.merge(:topic => topic, :related_item => Topic.find(1)))

    assert_equal topic, relation.topic
    assert_equal Topic.find(1), relation.related_item

    [Topic.find(1), topic].each do |t|
      t.reload
      assert_equal 1, t.related_topics.size
    end

    assert_equal Topic.find(1), topic.child_related_topics.first
    assert_equal topic, Topic.find(1).parent_related_topics.first

    topic.destroy

    assert_raises(ActiveRecord::RecordNotFound) { Topic.find(topic.id) }
    assert_raises(ActiveRecord::RecordNotFound) { ContentItemRelation.find(relation.id) }
    assert_raises(ActiveRecord::RecordNotFound) { ContentItemRelation::Deleted.find(relation.id) }
  end

  def test_related_topics_with_only_parent_topic_relations
    parent, parent2, child = create_topic_set(3)
    parents = parent, parent2

    parents.each do |p|
      ContentItemRelation.create!(:topic => p, :related_item => child)
      assert_equal 1, p.related_topics.size
    end

    assert_equal 2, child.child_content_item_relations.size
    assert_equal 2, child.parent_related_topics.size
    assert_equal 2, child.related_topics.size
  end

  def test_related_topics_with_only_child_topic_relations
    parent, child, child2 = create_topic_set(3)
    children = child, child2

    children.each do |c|
      ContentItemRelation.create!(:topic => parent, :related_item => c)
      assert_equal 1, c.related_topics.size
    end

    assert_equal 2, parent.content_item_relations.size
    assert_equal 2, parent.child_related_topics.size
    assert_equal 2, parent.related_topics.size
  end

  def test_related_topics_with_mixed_relations
    parent, subject, child = create_topic_set(3)

    ContentItemRelation.create!(:topic => parent, :related_item => subject)
    ContentItemRelation.create!(:topic => subject, :related_item => child)

    assert_equal parent, subject.parent_related_topics.first
    assert_equal child, subject.child_related_topics.first
    assert_equal 2, subject.related_topics.size
    assert_equal [parent, child], subject.related_topics
  end

  def test_related_topics_with_mixed_relations_and_only_non_pending
    parent, subject, child = create_topic_set(3)

    ContentItemRelation.create!(:topic => parent, :related_item => subject)
    ContentItemRelation.create!(:topic => subject, :related_item => child)

    assert_equal parent, subject.parent_related_topics.first
    assert_equal child, subject.child_related_topics.first
    assert_equal 2, subject.related_topics(true).size
    assert_equal [parent, child], subject.related_topics(true)
  end

  def test_related_topics_with_mixed_relations_and_only_non_pending2
    parent, parent_pending, subject, child, child_pending = create_topic_set(5)

    [parent_pending, child_pending].each do |topic|
      topic.update_attribute(:title, BLANK_TITLE)
    end

    # Topics/items pending moderation are expected to have no description
    parent_pending.update_attribute(:description, nil)
    child_pending.update_attribute(:description, nil)

    ContentItemRelation.create!(:topic => parent, :related_item => subject)
    ContentItemRelation.create!(:topic => parent_pending, :related_item => subject)
    ContentItemRelation.create!(:topic => subject, :related_item => child)
    ContentItemRelation.create!(:topic => subject, :related_item => child_pending)

    assert_equal 2, subject.parent_related_topics.size
    assert_equal 2, subject.child_related_topics.size
    assert_equal 4, subject.related_topics.size
    assert_equal 2, subject.related_topics(true).size
    assert_equal [parent, child], subject.related_topics(true)
  end

  private

  def create_topic_set(number_of_topics)
    array = []
    number_of_topics.times do
      array.push Topic.create!(@new_topic_model)
    end
    array
  end

  # James - 2008-06-13
  # Does not pass, unsure why right now; model attributes are identical.
  # def test_soft_delete_models_are_equal
  #   a = ContentItemRelation.create(@new_model)
  #   a.destroy
  #   b = ContentItemRelation::Deleted.find(a.id)
  #   b.position = nil
  #
  #   assert_soft_delete_models_are_equal a, b
  # end
end
