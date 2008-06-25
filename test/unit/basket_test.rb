require File.dirname(__FILE__) + '/../test_helper'

class BasketTest < Test::Unit::TestCase
  # fixtures preloaded

  def setup
    @base_class = "Basket"

    # hash of params to create new instance of model, e.g. {:name => 'Test Model', :description => 'Dummy'}
    @new_model = { :name => 'test basket', :private_default => false, :file_private_default => false }
    @req_attr_names = %w(name) 
    # name of fields that must be present, e.g. %(name description)
    @duplicate_attr_names = %w( ) # name of fields that cannot be a duplicate, e.g. %(name description)
  end

  # load in sets of tests and helper methods
  include KeteTestUnitHelper

  # make sure that basket names don't have special chars
  def test_validates_format_of
    special_chars = %w(: { } \\ / & ? < >)
    # the list above throws off syntax highlighting if it has single and double quotes
    # even though it's valid, adding here for clarity
    special_chars += ["'", "\""]

    special_chars.each do |special_char|
      basket = Basket.new(@new_model.merge({ :name => "something with a #{special_char}" }))
      assert !basket.valid?, "#{@base_class} with name that includes #{special_char} shouldn't be valid"
    end
  end

  def test_before_save_urlify_name
    basket = Basket.new(@new_model.merge({ :name => "something wicked this way comes" }))
    assert_nil basket.urlified_name, "#{@base_class}.urlified_name shouldn't have a value yet."
    basket.save!
    basket.reload
    assert_equal "something_wicked_this_way_comes", basket.urlified_name, "#{@base_class}.urlified_name should match this."
  end

  def test_update_index_topic
    basket = Basket.create(@new_model.merge({ :name => "something wicked this way comes" }))
    assert_nil basket.index_topic, "#{@base_class}.index_topic shouldn't have a value yet."
    index_topic = Topic.create!(:title => 'test topic', :basket => basket, :topic_type => TopicType.find(:first))
    basket.update_index_topic(index_topic)
    basket.reload
    assert_equal index_topic, basket.index_topic, "#{@base_class}.index_topic should match this."
  end

  def test_update_index_topic_destroy
    basket = Basket.create(@new_model.merge({ :name => "something wicked this way comes" }))
    index_topic = Topic.create!(:title => 'test topic', :basket => basket, :topic_type => TopicType.find(:first))
    basket.update_index_topic(index_topic)
    basket.reload
    basket.update_index_topic('destroy')
    basket.reload
    assert_nil basket.index_topic, "#{@base_class}.index_topic should have been made nil."
  end
  
  def test_basket_defaults
    basket = Basket.new
    assert  basket.new_record?
    
    assert_equal false, basket.private_default?
    assert_equal false, basket.file_private_default?
    assert_equal false, basket.allow_non_member_comments?
  end

  # TODO: tag_counts_array
  # TODO: index_page_order_tags_by

end
