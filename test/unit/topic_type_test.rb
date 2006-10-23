require File.dirname(__FILE__) + '/../test_helper'

class TopicTypeTest < Test::Unit::TestCase
  fixtures :topic_types

  # The TopicType model contains many things that
  # need to be tested using the join model TopicTypeToFieldMapping
  # and TopicTypeField, so we load their fixtures here
  fixtures :topic_type_fields
  fixtures :topic_type_to_field_mappings

  NEW_TOPIC_TYPE = {:name => 'Test TopicType', :description => 'Dummy'} # e.g. {:name => 'Test TopicType', :description => 'Dummy'}
  REQ_ATTR_NAMES       = %w(name description) # name of fields that must be present, e.g. %(name description)
  DUPLICATE_ATTR_NAMES = %w(name) # name of fields that cannot be a duplicate, e.g. %(name description)

  def setup
    # Retrieve fixtures via their name
    # @first = topic_types(:first)
    @person_type = topic_types(:person)
    @place_type = topic_types(:place)
    @name_field = topic_type_fields(:name)
    @capacity_field = topic_type_fields(:capacity)
  end

  def test_raw_validation
    topic_type = TopicType.new
    if REQ_ATTR_NAMES.blank?
      assert topic_type.valid?, "TopicType should be valid without initialisation parameters"
    else
      # If TopicType has validation, then use the following:
      assert !topic_type.valid?, "TopicType should not be valid without initialisation parameters"
      REQ_ATTR_NAMES.each {|attr_name| assert topic_type.errors.invalid?(attr_name.to_sym), "Should be an error message for :#{attr_name}"}
    end
  end

  def test_new
    topic_type = TopicType.new(NEW_TOPIC_TYPE)
    assert topic_type.valid?, "TopicType should be valid"
    NEW_TOPIC_TYPE.each do |attr_name|
      assert_equal NEW_TOPIC_TYPE[attr_name], topic_type.attributes[attr_name], "TopicType.@#{attr_name.to_s} incorrect"
    end
  end

  def test_validates_presence_of
    REQ_ATTR_NAMES.each do |attr_name|
      tmp_topic_type = NEW_TOPIC_TYPE.clone
      tmp_topic_type.delete attr_name.to_sym
      topic_type = TopicType.new(tmp_topic_type)
      assert !topic_type.valid?, "TopicType should be invalid, as @#{attr_name} is invalid"
      assert topic_type.errors.invalid?(attr_name.to_sym), "Should be an error message for :#{attr_name}"
    end
  end

  def test_duplicate
    current_topic_type = TopicType.find(:first)
    DUPLICATE_ATTR_NAMES.each do |attr_name|
      topic_type = TopicType.new(NEW_TOPIC_TYPE.merge(attr_name.to_sym => current_topic_type[attr_name]))
      assert !topic_type.valid?, "TopicType should be invalid, as @#{attr_name} is a duplicate"
      assert topic_type.errors.invalid?(attr_name.to_sym), "Should be an error message for :#{attr_name}"
    end
  end

  ### now for our joins

  # the straight has_many :topic_type_to_field_mappings
  # we'll leave the acts_as_list tests to join model itself

  # add a new field to the form, make sure that position and required are set correctly for defaults
  def test_straight_add_field_has_correct_defaults
    field = @person_type.topic_type_to_field_mappings.create(:topic_type_field_id => topic_type_fields(:city).id)
    assert_equal topic_type_fields(:city).id, field.topic_type_field_id
    assert_equal @person_type.topic_type_to_field_mappings.size, field.position
    assert !field.required?, "The default for required in topic_type_to_field_mappings should be false or nil."
  end

  # delete a topic type, makes sure dependent topic_type_to_field_mappings are deleted
  def test_straight_delete_topic_deletes_mappings
    topic_type_id = @person_type.id
    @person_type.destroy
    should_be_empty_list = TopicTypeToFieldMapping.find_all_by_topic_type_id(topic_type_id)
    assert_equal should_be_empty_list.size, 0, "After deleting a topic_type, it's associated form fields (mappings) should be deleted, too."
  end

  ## the has_many :through association extensions

  # form_fields
  # add a new field to the form using the extension, make sure that position and required are set correctly for defaults
  def test_form_fields_add_field_has_correct_defaults
    @place_type.form_fields << @name_field

    mapping =
      TopicTypeToFieldMapping.find(:first,
                                   :conditions => ["topic_type_field_id = :topic_type_field_id and topic_type_id = :topic_type_id",
                                                   {:topic_type_field_id => @name_field.id, :topic_type_id => @place_type.id }] )
    assert_equal @place_type.form_fields.size, mapping.position
    assert !mapping.required?, "The default for required in form_fields should be false or nil."
  end

  # topic_type.form_fields should be ordered by position
  def test_form_fields_ordered_by_position
    @place_type.form_fields << @name_field
    @place_type.form_fields << @capacity_field

    last_position = 0

    @place_type.form_fields.each do |field|
      mapping =
        TopicTypeToFieldMapping.find(:first,
                                     :conditions => ["topic_type_field_id = :topic_type_field_id and topic_type_id = :topic_type_id",
                                                     {:topic_type_field_id => field.id, :topic_type_id => @place_type.id }] )
      test_position = mapping.position.to_i
      last_position = test_position
      assert test_position <= last_position, "form_fields not listed in order of position"
    end
  end

  # required_form_fields
  # add a new field to the form using the extension, make sure that position and required are set correctly for defaults
  def test_required_form_fields_add_field_has_correct_defaults
    @place_type.required_form_fields << @capacity_field

    mapping =
      TopicTypeToFieldMapping.find(:first,
                                   :conditions => ["topic_type_field_id = :topic_type_field_id and topic_type_id = :topic_type_id",
                                                   {:topic_type_field_id => @capacity_field.id, :topic_type_id => @place_type.id }] )
    assert_equal @place_type.form_fields.size, mapping.position
    assert mapping.required?, "The default for required in required_form_fields should be true."
  end


  # topic_type.required_form_fields should be ordered by position
  def test_required_form_fields_ordered_by_position
    @place_type.required_form_fields << @name_field
    @place_type.required_form_fields << @capacity_field

    last_position = 0

    @place_type.required_form_fields.each do |field|
      mapping =
        TopicTypeToFieldMapping.find(:first,
                                     :conditions => ["topic_type_field_id = :topic_type_field_id and topic_type_id = :topic_type_id",
                                                     {:topic_type_field_id => field.id, :topic_type_id => @place_type.id }] )
      test_position = mapping.position.to_i
      last_position = test_position
      assert test_position <= last_position, "required_form_fields not listed in order of position"
    end
  end

  # we shouldn't see any fields that have been mapped to this topic_type already
  def test_available_fields_not_already_mapped
    @place_type.available_fields.each do |field|
      fcount = TopicTypeToFieldMapping.count :conditions => ["topic_type_field_id = :topic_type_field_id and topic_type_id = :topic_type_id",
                                              {:topic_type_field_id => field.id, :topic_type_id => @place_type.id }]
      assert_equal fcount, 0, "There is a field listed in available_fields that has already been mapped to this topic_type."
    end
  end
end

