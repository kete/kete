# test/unit/content_item_relation_test.rb tests that that join model works
# this is meant to test that each zoom class can use the content item relation join model
# except comments (that don't use content_item_relations)
module RelatedItemsTestUnitHelper
  # if you are using shoulda methods, you have to declare your tests this way
  def self.included(base)
    base.class_eval do
      context "A #{@base_class}" do
        setup do
          @related_item = Module.class_eval(@base_class).create! @new_model
          @topic_related_to = Basket.find(1).topics.create!({ title: 'The topic that the item is related to', topic_type_id: 1 })
        end

        should 'be able to be added as a content item relation to a topic' do
          ContentItemRelation.new_relation_to_topic(@topic_related_to, @related_item)

          relations = Array.new
          relations = unless @base_class == 'Topic'
            @topic_related_to.send(@base_class.tableize)
          else
            @topic_related_to.related_topics
                      end

          assert_equal relations.size, 1
        end
      end
    end
  end
end
