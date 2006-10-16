require File.dirname(__FILE__) + '/../test_helper'

class TopicTypeFieldTest < Test::Unit::TestCase
  fixtures :topic_type_fields

  # Replace this with your real tests.
  def test_truth
    assert true
  end

  def test_invalid_with_empty_name
    topic_type_field = TopicTypeField.new
    assert !topic_type_field.valid?
    assert topic_type_field.errors.invalid?(:name)
  end

  def test_unique_name
    topic_type_field = TopicTypeField.new(:name       => topic_type_fields(:first_names).name,
                          :description => "yyy")
    assert !topic_type_field.save
    assert_equal ActiveRecord::Errors.default_error_messages[:taken], topic_type_field.errors.on(:name)
  end

end
