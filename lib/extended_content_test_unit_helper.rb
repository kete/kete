require 'rexml/document'

module ExtendedContentTestUnitHelper
  # xml attributes pulls extended_content column xml out into a hash
  # TODO: test case where the model is a topic and we need form fields from ancestors
  # TODO: test case where extended_field is a multiple
  # TODO: test that position is in right order?
  def test_xml_attributes_without_position
    model = Module.class_eval(@base_class).create!(new_model_attributes)
    model.update_attribute(:extended_content, '<some_tag>something</some_tag>')

    assert model.valid?

    assert_equal '<some_tag>something</some_tag>', model.extended_content
    assert_equal 'something', model.xml_attributes_without_position['some_tag']
  end

  def test_xml_attributes_without_position_without_data
    model = Module.class_eval(@base_class).create!(new_model_attributes)

    model.update_attribute(:extended_content, '')

    assert model.valid?

    assert_equal '', model.extended_content
    assert model.xml_attributes_without_position.empty?
  end

  def test_extended_content
    model = Module.class_eval(@base_class).create!(new_model_attributes)
    model.update_attribute(:extended_content, '<some_tag xml_element_name="dc:something">something</some_tag>')

    assert model.valid?

    assert_equal '<some_tag xml_element_name="dc:something">something</some_tag>', model.extended_content
    assert_equal({ 'xml_element_name' => 'dc:something', 'value' => 'something' }, model.extended_content_values['some_tag'])
  end

  def test_extended_content_with_multiple_nodes
    model = Module.class_eval(@base_class).create!(new_model_attributes)
    model.update_attribute(:extended_content, '<some_tag xml_element_name="dc:something">something</some_tag><some_other_tag xml_element_name="dc:something_else">something_else</some_other_tag>')

    assert model.valid?

    assert_equal '<some_tag xml_element_name="dc:something">something</some_tag><some_other_tag xml_element_name="dc:something_else">something_else</some_other_tag>', model.extended_content
    assert_equal 2, model.extended_content_values.size
    assert_equal({ 'xml_element_name' => 'dc:something', 'value' => 'something' }, model.extended_content_values['some_tag'])
    assert_equal({ 'xml_element_name' => 'dc:something_else', 'value' => 'something_else' }, model.extended_content_values['some_other_tag'])
  end

  def test_extended_content_without_data
    model = Module.class_eval(@base_class).create!(new_model_attributes)
    model.update_attribute(:extended_content, '')

    assert model.valid?

    assert_equal '', model.extended_content
    assert model.extended_content_values.empty?
  end

  def test_extended_content_pairs
    # Test with a single node
    model = Module.class_eval(@base_class).create!(new_model_attributes)
    model.update_attribute(:extended_content, '<some_tag xml_element_name="dc:something">something</some_tag>')

    assert model.valid?

    assert_equal '<some_tag xml_element_name="dc:something">something</some_tag>', model.extended_content
    assert_equal [['some_tag', 'something']].sort, model.extended_content_pairs.sort

    # Test with multiple nodes
    model = Module.class_eval(@base_class).create!(new_model_attributes)
    model.update_attribute(:extended_content, '<some_tag xml_element_name="dc:something">something</some_tag><some_other_tag xml_element_name="dc:something_else">something_else</some_other_tag>')

    assert model.valid?

    assert_equal '<some_tag xml_element_name="dc:something">something</some_tag><some_other_tag xml_element_name="dc:something_else">something_else</some_other_tag>', model.extended_content
    assert_equal [['some_other_tag', 'something_else'], ['some_tag', 'something']], model.extended_content_pairs
  end

  def test_extended_content_setter_with_undefined_field
    model = Module.class_eval(@base_class).create!(new_model_attributes)
    model.extended_content_values = { 'some_tag' => 'value' }

    assert model.valid?

    # We can't expect the XML to be empty because empty tags will be generated for all mapped extended fields.
    # assert_equal '', model.extended_content

    assert_nil model.extended_content_values['some_tag']
  end

  # See individual model tests for model specific tests, i.e. TopicTest.
  # Because there are no extended fields mapped to all item classes, all setter type tests must be performed there.

  # if you are using shoulda methods, you have to declare your tests this way
  def self.included(base)
    base.class_eval do
      # test around setter and getter methods generated for each extended field
      context 'An extended field mapped to a type' do
        setup do
          create_and_map_extended_field_to_type(label: 'Some tag')
        end

        should 'have a method that will set its value' do
          method_name = @extended_field.label_for_params + '='
          # not sure if respond_to? works in the context of method missing
          # may need a begin rescue block instead
          # assert_equal @extended_item.respond_to?(method_name), true

          @extended_item.send(method_name, 'something')
          assert_equal 'something', @extended_item.xml_attributes_without_position['some_tag']
        end

        should 'have a method that will append its value to existing value' do
          @extended_item.update_attribute(:extended_content, '<some_tag>something</some_tag>')
          @extended_item.send(@extended_field.label_for_params + '+=', 'something')
          assert_equal 'something' + 'something', @extended_item.xml_attributes_without_position['some_tag']
        end

        should 'have a method that will set return its value' do
          @extended_item.update_attribute(:extended_content, '<some_tag>something</some_tag>')
          assert_equal @extended_item.xml_attributes_without_position['some_tag'], @extended_item.send(@extended_field.label_for_params)
        end

        should "build xml unless for private fields and the item isn't private" do
          return if @base_class == 'User' # users do not have private fields

          @extended_item.update_attributes(extended_content_values: { 'some_tag' => 'something' })
          assert @extended_item.extended_content.include?('<some_tag>something</some_tag>')

          @mapping.update_attribute(:private_only, true)

          @extended_item.update_attributes(extended_content_values: { 'some_tag' => 'something' }, private: false)
          assert !@extended_item.extended_content.include?('<some_tag>something</some_tag>')

          @extended_item.update_attributes(extended_content_values: { 'some_tag' => 'something' }, private: true)

          if @base_class == 'Comment'
            # comments don't have private_version_serialized
            assert @extended_item.private?
            assert @extended_item.extended_content.include?('<some_tag>something</some_tag>')
          else
            # public version shouldn't have this info
            assert !@extended_item.extended_content.include?('<some_tag>something</some_tag>')
            # private version should have the info
            assert @extended_item.private_version_serialized.include?('<some_tag>something</some_tag>')
          end
        end
      end

      private

      include ExtendedContentHelpersForTestSetUp
    end
  end

  protected

  def new_model_attributes
    @new_model
  end
end
