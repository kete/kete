require File.dirname(__FILE__) + '/../test_helper'

class TopicTypeToFieldMappingTest < Test::Unit::TestCase
  # since this is a join model, we need to load test data
  # for the models it joins
  fixtures :topic_types
  fixtures :topic_type_fields

  fixtures :topic_type_to_field_mappings

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
