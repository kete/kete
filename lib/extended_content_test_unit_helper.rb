require "rexml/document"

module ExtendedContentTestUnitHelper
  # xml attributes pulls extended_content column xml out into a hash
  # TODO: test case where there are no extended fields associated with this model
  # TODO: test case where extended_content is blank
  # TODO: test case where the model is a topic and we need form fields from ancestors
  # TODO: test case where extended_field is a multiple
  # TODO: test that position is in right order?

  def test_xml_attributes_without_position
    model = Module.class_eval(@base_class).create!(new_model_attributes)    
    model.update_attribute(:extended_content, '<some_tag>something</some_tag>')
    
    assert_valid model
    
    assert_equal '<some_tag>something</some_tag>', model.extended_content
    assert_equal 'something', model.xml_attributes_without_position['some_tag']
  end
  
  def test_xml_attributes_without_position_without_data
    model = Module.class_eval(@base_class).create!(new_model_attributes)
    
    model.update_attribute(:extended_content, '')
    
    assert_valid model
    
    assert_equal '', model.extended_content
    assert_nil model.xml_attributes_without_position
  end
  
  # See individual model tests for model specific tests, i.e. TopicTest.
  # Because there are no extended fields mapped to all item classes, all setter type tests must be performed there.
  
  protected
  
    def new_model_attributes
      @new_model
    end
  
  
end
