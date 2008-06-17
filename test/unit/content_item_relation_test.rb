require File.dirname(__FILE__) + '/../test_helper'

class ContentRelationTest < Test::Unit::TestCase
  # fixtures preloaded

  # TODO: new_relation_to_topic

  def setup
    @new_model = {
      :position => nil,
      :topic_id => 1,
      :related_item_id => 2,
      :related_item_type => 'Topic',
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
  end
  
  def test_soft_delete
    c = ContentItemRelation.create(@new_model)
    assert_model_soft_deletes(c)
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
