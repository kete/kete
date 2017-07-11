# functionality for merging versions of an item
# to create a new version
module MergeTestUnitHelper
  # if you are using shoulda methods, you have to declare your tests this way
  def self.included(base)
    base.class_eval do
      context "A #{@base_class}" do
        setup do
          should_create_extended_item = @base_class == 'WebLink' ? false : true
          create_and_map_extended_field_to_type(label: 'First',
                                                should_create_extended_item: should_create_extended_item)
          create_and_map_extended_field_to_type(label: 'Second',
                                                should_create_extended_item: should_create_extended_item)

          @item = Module.class_eval(@base_class).create! @new_model

          @item.first = "version 2"
          @item.save!

          @item.reload

          @item.second = "version 3"
          @item.save!

          @item.reload
        end

        should "be able to be merge specified versions of an item to create a new merged version" do
          @item.merge_values_from(2,3)
          @item.save!
          @item.reload

          assert_equal @item.first, "version 2"
          assert_equal @item.second, "version 3"
        end

        should "be able to be merge specified versions of an item to create a new merged version and have last specified version's value take precedence when value exists in earlier version" do
          @item.title = "version 4"
          @item.first = "version 4"
          @item.save!
          @item.reload

          @item.merge_values_from(2,3,4)
          @item.save!

          assert_equal @item.title, "version 4"
          assert_equal @item.first, "version 4"
          assert_equal @item.second, "version 3"
        end

      end
      include ExtendedContentHelpersForTestSetUp
    end
  end
end
