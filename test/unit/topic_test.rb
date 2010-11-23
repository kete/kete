require File.dirname(__FILE__) + '/../test_helper'

class TopicTest < ActiveSupport::TestCase
  # fixtures preloaded

  def setup
    @base_class = "Topic"

    # Extend the base class so test files from attachment_fu get put in the
    # tmp directory, and not in the development/production directories.
    eval(@base_class).send(:include, ItemPrivacyTestHelper::Model)

    # hash of params to create new instance of model, e.g. {:name => 'Test Model', :description => 'Dummy'}
    @new_model = {
      :title => 'test item',
      :topic_type => TopicType.find(:first),
      :basket => Basket.find(:first)
      # :extended_content => { "first_names" => "Joe", "last_name" => "Bloggs" }
    }

    # name of fields that must be present, e.g. %(name description)
    @req_attr_names = %w(title)
    # name of fields that cannot be a duplicate, e.g. %(name description)
    @duplicate_attr_names = %w( )
  end

  # load in sets of tests and helper methods
  include KeteTestUnitHelper
  include HasContributorsTestUnitHelper
  include ExtendedContentTestUnitHelper
  include FlaggingTestUnitHelper
  include RelatedItemsTestUnitHelper
  include ItemPrivacyTestHelper::TestHelper
  include ItemPrivacyTestHelper::Tests::VersioningAndModeration
  include ItemPrivacyTestHelper::Tests::TaggingWithPrivacyContext
  include ItemPrivacyTestHelper::Tests::MovingItemsBetweenBasketsWithDifferentPrivacies

  def test_does_not_respond_to_file_private
    topic = Topic.create

    assert !topic.respond_to?(:file_private)
    assert !topic.respond_to?(:file_private=)
  end

  # Topic specific extended content tests

  def test_extended_content_setter
    model = Topic.new(@new_model.merge(:topic_type => TopicType.find_by_name("Person")))
    model.extended_content_values = { "first_names" => "Joe", "last_name" => "Bloggs" }
    model.save!

    assert model.valid?

    assert_equal '<first_names xml_element_name="dc:description">Joe</first_names><last_name>Bloggs</last_name><place_of_birth xml_element_name="dc:subject"></place_of_birth>', model.extended_content
  end

  def test_xml_attributes
    model = Topic.new(@new_model.merge(:topic_type => TopicType.find_by_name("Person")))
    model.update_attribute(:extended_content, '<first_names xml_element_name="dc:description">Joe</first_names><last_name>Bloggs</last_name><place_of_birth xml_element_name="dc:subject"></place_of_birth>')

    assert model.valid?

    assert_equal({ "1" => { "first_names" => {"xml_element_name"=>"dc:description", "value"=>"Joe"} }, "2" => { "last_name" => "Bloggs" }, "3" => { "place_of_birth" => { "xml_element_name" => "dc:subject" } } }, model.xml_attributes)
  end

  def test_xml_attributes_without_data
    model = Topic.new(@new_model.merge(:topic_type => TopicType.find_by_name("Person")))
    model.update_attribute(:extended_content, '')

    assert model.valid?

    assert_equal({}, model.xml_attributes)
  end

  def test_xml_attributes_without_position_with_multiple_field_values
    for_topic_with(TopicType.find_by_name("Person"), { :label => "Address", :multiple => true}) do |t|
      t.extended_content_values = {
        "first_names" => "Joe",
        "last_name" => "Bloggs",
        "address" => { "1" => "The Parade", "2" => "Island Bay" }
      }

      assert t.valid?
      assert_equal({
        "first_names"=> { "xml_element_name" => "dc:description", "value" => "Joe" },
        "address_multiple"=> {
          "1" => { "address" => { "xml_element_name" => "dc:description", "value" => "The Parade" } },
          "2" => { "address" => { "xml_element_name" => "dc:description", "value" => "Island Bay" } }
        },
       "place_of_birth" => { "xml_element_name" => "dc:subject" },
       "last_name" => "Bloggs" }, t.xml_attributes_without_position)
    end
  end

  def test_extended_content_pairs_with_multiple_field_values

    field = ExtendedField.create!(
      :label => "Address",
      :xml_element_name => "dc:description",
      :multiple => true,
      :ftype => "text"
    )

    topic_type = TopicType.find_by_name("Person")
    topic_type.form_fields << field
    topic_type.save!

    model = Topic.new(@new_model.merge(:topic_type => topic_type))
    model.extended_content_values = { "first_names" => "Joe", "last_name" => "Bloggs", "address" => { "1" => "Wollaston St.", "2" => "Nelson" } }

    assert_nothing_raised do
      model.save!
    end

    assert_equal [["first_names", "Joe"], ["last_name", "Bloggs"], ["address_multiple", [["Wollaston St."], ["Nelson"]]], ["place_of_birth", nil]].sort, \
      model.extended_content_pairs.sort

  end

  def test_extended_field_required_fields_are_validated

    # Test with valid fields
    model = Topic.new(@new_model.merge(:topic_type => TopicType.find_by_name("Person")))
    model.extended_content_values = { "first_names" => "Joe", "last_name" => "Bloggs", "city" => "Wellington" }

    assert model.valid?

    assert_nothing_raised do
      model.save!
    end

    # Test with invalid fields
    model = Topic.new(@new_model.merge(:topic_type => TopicType.find_by_name("Person")))
    model.extended_content_values = { "first_names" => "", "last_name" => "Bloggs Fam." }
    assert_equal [["first_names", nil], ["last_name", "Bloggs Fam."], ["place_of_birth", nil]].sort, model.extended_content_pairs.sort
    assert !model.valid?
    assert_equal 1, model.errors.size

    assert_raises ActiveRecord::RecordInvalid do
      model.save!
    end
  end

  def test_extended_field_required_fields_are_validated_with_multiples
    topic_type = add_field_to(TopicType.find_by_name("Person"), { :label => "Address", :multiple => true }, { :required => true })

    model = Topic.new(@new_model.merge(:topic_type => topic_type))
    model.extended_content_values = { "first_names" => "Joe", "last_name" => "Bloggs", "address" => { "1" => "Wollaston St.", "2" => "" } }

    assert model.valid?

    model.extended_content_values = { "first_names" => "Joe", "last_name" => "Bloggs", "address" => { "1" => "", "2" => "" } }

    assert !model.valid?
    assert_equal 1, model.errors.size

    # Drop our newly created field and mapping
    drop_last_field!
  end

  def test_helpers_work
    for_topic_with(TopicType.find_by_name("Person"), { :label => "Address", :ftype => "textarea" }) do |t|
      t.extended_content_values = { "first_names" => "Joe", "last_name" => "Bloggs" }
      assert t.valid?
      assert_kind_of Topic, t
    end
  end

  def test_extended_field_text_fields_are_validated
    model = Topic.new(@new_model.merge(:topic_type => TopicType.find_by_name("Person")))
    model.extended_content_values = { "first_names" => "Joe", "last_name" => "Bloggs" }

    assert model.valid?
    assert_equal 0, model.errors.size
  end

  def test_extended_field_textarea_fields_are_validated
    for_topic_with(TopicType.find_by_name("Person"), { :label => "Address", :ftype => "textarea" }) do |t|
      t.extended_content_values = { "first_names" => "Joe", "last_name" => "Bloggs", "address" => "New\n Line" }
      assert t.valid?
    end
  end

  # TODO: We do not have a plan for how radio fields are to be used in Kete.
  #def test_extended_field_radio_fields_are_validated
  #  print "Skipped"
  #end

  def test_extended_field_date_fields_are_validated
    for_topic_with(TopicType.find_by_name("Person"), { :label => "Birthdate", :ftype => "date" }) do |t|
      compulsory_content = { "first_names" => "Joe", "last_name" => "Bloggs" }

      t.extended_content_values = compulsory_content.merge("birthdate" => "1960-01-01")
      assert t.valid?

      t.extended_content_values = compulsory_content.merge("birthdate" => "In 1960")
      assert !t.valid?
      assert_equal 1, t.errors.size
      assert_equal "Birthdate must be in the standard date format (YYYY-MM-DD)", t.errors.full_messages.join(", ")

      t.extended_content_values = compulsory_content.merge("birthdate" => "1960-1-1")
      assert !t.valid?
      assert_equal 1, t.errors.size
      assert_equal "Birthdate must be in the standard date format (YYYY-MM-DD)", t.errors.full_messages.join(", ")
    end
  end

  def test_extended_field_checkbox_fields_are_validated
    for_topic_with(TopicType.find_by_name("Person"), { :label => "Deceased", :ftype => "checkbox" }) do |t|
      compulsory_content = { "first_names" => "Joe", "last_name" => "Bloggs" }

      ["Yes", "No", "yes", "no", ""].each do |value|
        t.extended_content_values = compulsory_content.merge("deceased" => value)
        assert t.valid?
        assert_equal 0, t.errors.size
      end

      [1, 0].each do |value|
        t.extended_content_values = compulsory_content.merge("deceased" => value)
        assert !t.valid?
        assert_equal "Deceased must be a valid checkbox value (Yes or No)", t.errors.full_messages.join(", ")
      end
    end
  end

  def test_extended_field_choice_fields_are_validated
    for_topic_with(TopicType.find_by_name("Person"), { :label => "Marital status", :ftype => "choice" }) do |t|
      compulsory_content = { "first_names" => "Joe", "last_name" => "Bloggs" }

      # Set up choices
      choice_content = [
        ["Married", "Married"],
        ["Defacto relationship", "Defacto Relationship"],
        ["Dating", "Dating"],
        ["Single", "Single"]
      ]

      choice_content.each do |l, v|
        c = Choice.create!(:label => l, :value => v)
        ExtendedField.last.choices << c
      end

      assert_equal 4, t.all_field_mappings.last.extended_field.choices.size

      # Run the tests
      ["", "Married", "Defacto Relationship", "Dating", "Single"].each do |value|
        t.extended_content_values = compulsory_content.merge("marital_status" => value)
        assert t.valid?
        assert_equal 0, t.errors.size
      end

      ["married", "something else", "123", "Defacto", "Defacto relationship"].each do |v|
        t.extended_content_values = compulsory_content.merge("marital_status" => v)
        assert !t.valid?
        assert_equal 1, t.errors.size
        assert_equal "Marital status must be a valid choice", t.errors.full_messages.join(", ")
      end

      ExtendedField.last.choices.each { |c| c.destroy }
      assert_equal 0, ExtendedField.last.choices.size
    end
  end

  def test_adding_a_new_extended_field_renders_all_versions_invalid

    # Create a topic
    topic_type = TopicType.create!(:name => "Test", :description => "A test", :parent_id => 1)
    topic = Topic.create!(@new_model.merge(:topic_type => topic_type))

    # Update it and check that it's still valid
    topic.update_attributes! :description => "Changed description"
    assert topic.valid?

    # Add a new required field to the topic type
    add_field_to(topic_type, { :label => "Is a test" }, :required => true)

    # The current version is still valid as it never had a value for the extended content.
    assert topic.valid?

    # But updating the topic requires a value to be passed now, because it is a new requirement.
    assert !topic.update_attributes(:description => "Updated description again", :extended_content_values => { "is_a_test" => "" })
    assert !topic.valid?

    assert topic.update_attributes( \
      :description => "Updated description again",
      :extended_content_values => { "is_a_test" => "Yes" }
    )

    assert topic.valid?
  end


  def test_empty_values_are_validated_correctly_on_new_records
    topic_type = TopicType.create!(:name => "Test", :description => "A test", :parent_id => 1)
    add_field_to(topic_type, { :label => "Is a test" }, :required => true)

    topic = Topic.new(@new_model.merge(:topic_type => topic_type))
    topic.extended_content_values = { "is_a_test" => "Yes" }

    assert topic.valid?

    topic = Topic.new(@new_model.merge(:topic_type => topic_type))
    topic.extended_content_values = { "is_a_test" => "" }

    assert !topic.valid?
  end

  def test_empty_values_are_validated_correctly_on_existing_records
    topic_type = TopicType.create!(:name => "Test", :description => "A test", :parent_id => 1)
    topic = Topic.new(@new_model.merge(:topic_type => topic_type))
    assert topic.valid?

    add_field_to(topic_type, { :label => "Is a test" }, :required => true)
    assert topic.valid?

    topic.extended_content_values = { "is_a_test" => "Yes" }
    assert topic.valid?
  end

  def test_empty_values_are_validated_correctly_on_existing_records_with_multiples
    topic_type = TopicType.create!(:name => "Test", :description => "A test", :parent_id => 1)
    topic = Topic.new(@new_model.merge(:topic_type => topic_type))
    assert topic.valid?

    add_field_to(topic_type, { :multiple => true, :label => "Is a test" }, :required => true)
    assert topic.valid?

    topic.extended_content_values = { "is_a_test" => { "1" => "Yes" } }
    assert topic.valid?

    topic.extended_content_values = { "is_a_test" => { "1" => "" } }
    assert !topic.valid?

    topic.extended_content_values = nil
    assert topic.valid?
  end

  def test_empty_values_are_validated_correctly_on_existing_records_with_multiples_and_nil_values_disallowed
    topic_type = TopicType.create!(:name => "Test", :description => "A test", :parent_id => 1)
    topic = Topic.new(@new_model.merge(:topic_type => topic_type))
    topic.send(:allow_nil_values_for_extended_content=, false)

    assert topic.valid?

    assert_equal false, topic.send(:allow_nil_values_for_extended_content)

    add_field_to(topic_type, { :multiple => true, :label => "Is a test" }, :required => true)
    assert !topic.valid?

    topic.extended_content_values = { "is_a_test" => { "1" => "Yes" } }
    assert topic.valid?

    topic.extended_content_values = { "is_a_test" => { "1" => "" } }
    assert !topic.valid?

    topic.extended_content_values = nil
    assert !topic.valid?
  end
  def test_structured_extended_content_getter
    for_topic_with(TopicType.find_by_name("Person"), { :label => "Address", :multiple => true}) do |t|
      t.extended_content_values = {
        "first_names" => "Joe",
        "last_name" => "Bloggs",
        "address" => { "1" => "The Parade", "2" => "Island Bay" }
      }

      assert t.valid?

      expected_hash = {
        "first_names" => [["Joe"]],
        "last_name" => [["Bloggs"]],
        "place_of_birth" => [[nil]],
        "address" => [["The Parade"], ["Island Bay"]]
      }
      assert_equal expected_hash, t.structured_extended_content
    end
  end

  def test_structured_extended_content_getter_with_choices
    for_topic_with(TopicType.find_by_name("Person"), { :label => "Marital status", :ftype => "choice", :multiple => false }) do |t|
      compulsory_content = { "first_names" => "Joe", "last_name" => "Bloggs" }

      # Set up choices
      choice_content = [
        ["Married", "Married"],
        ["Defacto relationship", "Defacto Relationship"],
        ["Dating", "Dating"],
        ["Single", "Single"]
      ]

      choice_content.each do |l, v|
        c = Choice.create!(:label => l, :value => v)
        ExtendedField.last.choices << c
      end

      t.extended_content_values = compulsory_content.merge("marital_status" => { "1" => "Married", "2" => "Dating" })

      assert_equal({ "first_names" => [["Joe"]], "last_name" => [["Bloggs"]], "marital_status" => [["Married", "Dating"]], "place_of_birth" => [[nil]] }, t.structured_extended_content)
    end
  end

  def test_structured_extended_content_getter_with_multiple_choices
    for_topic_with(TopicType.find_by_name("Person"), { :label => "Marital status", :ftype => "choice", :multiple => true }) do |t|
      compulsory_content = { "first_names" => "Joe", "last_name" => "Bloggs" }

      # Set up choices
      choice_content = [
        ["Married", "Married"],
        ["Defacto relationship", "Defacto Relationship"],
        ["Dating", "Dating"],
        ["Single", "Single"]
      ]

      choice_content.each do |l, v|
        c = Choice.create!(:label => l, :value => v)
        ExtendedField.last.choices << c
      end

      t.extended_content_values = compulsory_content.merge("marital_status" => { "1" => { "1" => "Married", "2" => "Dating" }, "2" => { "1" => "Single" } })

      assert_equal({ "first_names" => [["Joe"]], "last_name" => [["Bloggs"]], "marital_status" => [["Married", "Dating"], ["Single"]], "place_of_birth" => [[nil]] }, t.structured_extended_content)
    end
  end

  def test_structured_extended_content_getter_with_no_values
    for_topic_with(TopicType.find_by_name("Person"), { :label => "Address", :multiple => true}) do |t|
      t.extended_content = nil

      assert_equal({}, t.structured_extended_content)
    end
  end

  def test_structured_extended_content_setter
    for_topic_with(TopicType.find_by_name("Person"), { :label => "Address", :multiple => true}) do |t|
      t.structured_extended_content = {
        "first_names" => [["Joe"]],
        "last_name" => [["Bloggs"]],
        "place_of_birth" => [[nil]],
        "address" => [["The Parade"], ["Island Bay"]]
      }

      assert t.valid?

      expected_value = '<first_names xml_element_name="dc:description">Joe</first_names><last_name>Bloggs</last_name><place_of_birth xml_element_name="dc:subject"></place_of_birth><address_multiple><1><address xml_element_name="dc:description">The Parade</address></1><2><address xml_element_name="dc:description">Island Bay</address></2></address_multiple>'
      assert_equal expected_value, t.extended_content
    end
  end

  def test_structured_extended_content_setter_with_choices
    for_topic_with(TopicType.find_by_name("Person"), { :label => "Marital status", :ftype => "choice", :multiple => false }) do |t|
      compulsory_content = { "first_names" => "Joe", "last_name" => "Bloggs" }

      # Set up choices
      choice_content = [
        ["Married", "Married"],
        ["Defacto relationship", "Defacto Relationship"],
        ["Dating", "Dating"],
        ["Single", "Single"]
      ]

      choice_content.each do |l, v|
        c = Choice.create!(:label => l, :value => v)
        ExtendedField.last.choices << c
      end

      t.structured_extended_content = {
        "first_names" => [["Joe"]],
        "last_name" => [["Bloggs"]],
        "marital_status" => [["Married", "Dating"]],
        "place_of_birth" => [[nil]]
      }

      expected_hash = {
        "first_names" => [["Joe"]],
        "marital_status" => [["Married", "Dating"]],
        "place_of_birth" => [[nil]],
        "last_name" => [["Bloggs"]]
      }

      assert_equal(expected_hash, t.structured_extended_content)

      expected_value = '<first_names xml_element_name="dc:description">Joe</first_names><last_name>Bloggs</last_name><place_of_birth xml_element_name="dc:subject"></place_of_birth><marital_status xml_element_name="dc:description"><1>Married</1><2>Dating</2></marital_status>'

      assert_equal expected_value, t.extended_content
    end
  end

  def test_structured_extended_content_setter_with_multiple_choices
    for_topic_with(TopicType.find_by_name("Person"), { :label => "Marital status", :ftype => "choice", :multiple => true }) do |t|
      compulsory_content = { "first_names" => "Joe", "last_name" => "Bloggs" }

      # Set up choices
      choice_content = [
        ["Married", "Married"],
        ["Defacto relationship", "Defacto Relationship"],
        ["Dating", "Dating"],
        ["Single", "Single"]
      ]

      choice_content.each do |l, v|
        c = Choice.create!(:label => l, :value => v)
        ExtendedField.last.choices << c
      end

      t.structured_extended_content = {
        "first_names" => [["Joe"]],
        "last_name" => [["Bloggs"]],
        "marital_status" => [["Married", "Dating"], ["Single"]],
        "place_of_birth" => [[nil]]
      }

      expected_hash = {
        "first_names" => [["Joe"]],
        "marital_status" => [["Married", "Dating"], ["Single"]],
        "place_of_birth" => [[nil]],
        "last_name" => [["Bloggs"]]
      }

      assert_equal(expected_hash, t.structured_extended_content)

      expected_value = '<first_names xml_element_name="dc:description">Joe</first_names><last_name>Bloggs</last_name><place_of_birth xml_element_name="dc:subject"></place_of_birth><marital_status_multiple><1><marital_status xml_element_name="dc:description"><1>Married</1><2>Dating</2></marital_status></1><2><marital_status xml_element_name="dc:description"><1>Single</1></marital_status></2></marital_status_multiple>'

      assert_equal expected_value, t.extended_content
    end
  end

  def test_extended_content_accessors_with_multiple_choices
    for_topic_with(TopicType.find_by_name("Person"), { :label => "Marital status", :ftype => "choice", :multiple => true }) do |t|
      compulsory_content = { "first_names" => "Joe", "last_name" => "Bloggs" }

      # Set up choices
      choice_content = [
        ["Married", "Married"],
        ["Defacto relationship", "Defacto Relationship"],
        ["Dating", "Dating"],
        ["Single", "Single"]
      ]

      choice_content.each do |l, v|
        c = Choice.create!(:label => l, :value => v)
        ExtendedField.last.choices << c
      end

      t.structured_extended_content = {
        "first_names" => [["Joe"]],
        "last_name" => [["Bloggs"]],
        "marital_status" => [["Married", "Dating"], ["Single"]],
        "place_of_birth" => [[nil]]
      }

      assert_equal "Joe", t.first_names
      assert_equal ["Married -> Dating", "Single"], t.marital_status
      assert_equal "", t.place_of_birth

      t.marital_status = "Married"
      assert_equal "Married", t.marital_status
      assert t.extended_content.include?("<1><marital_status xml_element_name=\"dc:description\">Married</marital_status></1>")

      t.send("marital_status+=", "Single")
      assert_equal ["Married", "Single"], t.marital_status
      expected = "<1><marital_status xml_element_name=\"dc:description\">Married</marital_status></1>"
      expected += "<2><marital_status xml_element_name=\"dc:description\">Single</marital_status></2>"
      assert t.extended_content.include?(expected), "#{expected} should be in extended content, but isn't. #{t.extended_content}"

      t.send("first_names+=", " John")
      assert_equal "Joe John", t.first_names
    end
  end

  def test_extended_content_accessors_with_choices
    for_topic_with(TopicType.find_by_name("Person"), { :label => "Marital status", :ftype => "choice", :multiple => false }) do |t|
      compulsory_content = { "first_names" => "Joe", "last_name" => "Bloggs" }

      # Set up choices
      choice_content = [
        ["Married", "Married"],
        ["Defacto relationship", "Defacto Relationship"],
        ["Dating", "Dating"],
        ["Single", "Single"]
      ]

      choice_content.each do |l, v|
        c = Choice.create!(:label => l, :value => v)
        ExtendedField.last.choices << c
      end

      t.structured_extended_content = {
        "first_names" => [["Joe"]],
        "last_name" => [["Bloggs"]],
        "marital_status" => [["Married", "Dating"]],
        "place_of_birth" => [[nil]]
      }

      assert_equal "Joe", t.first_names
      assert_equal "Married -> Dating", t.marital_status
      assert_equal "", t.place_of_birth

      t.marital_status = "Single"
      assert_equal "Single", t.marital_status

      assert t.extended_content.include?("<marital_status xml_element_name=\"dc:description\"><1>Single</1></marital_status>")
    end
  end

  protected

    # Some helpers for extended field tests
    # Returns instance of TopicType.
    def add_field_to(topic_type, field_attribute_hash = {}, mapping_options = {})

      default_field_attributes = {
        :label => "Test",
        :xml_element_name => "dc:description",
        :multiple => false,
        :ftype => "text"
      }

      mapping_attributes = {
        :extended_field => ExtendedField.create!(default_field_attributes.merge(field_attribute_hash)),
        :required => false
      }

      topic_type.topic_type_to_field_mappings.create(mapping_attributes.merge(mapping_options))

      topic_type
    end

    def for_topic_with(topic_type, field_attribute_hash = {}, mapping_options = {})
      tt = add_field_to(topic_type, field_attribute_hash, mapping_options)
      model = Topic.new(@new_model.merge(:topic_type => tt))
      yield(model)
      drop_last_field!
    end

    def drop_last_field!
      ExtendedField.last.destroy
      TopicTypeToFieldMapping.last.destroy
    end

end

