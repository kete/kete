# frozen_string_literal: true

require File.dirname(__FILE__) + '/../test_helper'

class TopicTest < ActiveSupport::TestCase
  # fixtures preloaded
  include KeteUrlFor

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
    @duplicate_attr_names = %w()
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

  include MergeTestUnitHelper

  def test_does_not_respond_to_file_private
    topic = Topic.create

    assert !topic.respond_to?(:file_private)
    assert !topic.respond_to?(:file_private=)
  end

  # Topic specific extended content tests

  def test_extended_content_setter
    model = create_person(:do_not_save => false)

    assert model.valid?

    assert_equal '<first_names xml_element_name="dc:description">Joe</first_names><last_name>Bloggs</last_name><place_of_birth xml_element_name="dc:subject"></place_of_birth>', model.extended_content
  end

  def test_xml_attributes
    model = Topic.new(@new_model.merge(:topic_type => TopicType.find_by_name("Person")))
    model.update_attribute(:extended_content, '<first_names xml_element_name="dc:description">Joe</first_names><last_name>Bloggs</last_name><place_of_birth xml_element_name="dc:subject"></place_of_birth>')

    assert model.valid?

    assert_equal({ "1" => { "first_names" => { "xml_element_name" => "dc:description", "value" => "Joe" } }, "2" => { "last_name" => "Bloggs" }, "3" => { "place_of_birth" => { "xml_element_name" => "dc:subject" } } }, model.xml_attributes)
  end

  def test_xml_attributes_without_data
    model = create_person
    model.update_attribute(:extended_content, '')

    assert model.valid?

    assert_equal({}, model.xml_attributes)
  end

  def test_xml_attributes_without_position_with_multiple_field_values
    for_topic_with(TopicType.find_by_name("Person"), { :label => "Address", :multiple => true }) do |t|
      t.extended_content_values = default_extended_values_plus("address" => { 
                                                                 "1" => "The Parade",
                                                                 "2" => "Island Bay" 
                                                               })
      assert t.valid?
      assert_equal(
        {
          "first_names" => { "xml_element_name" => "dc:description", "value" => "Joe" },
          "address_multiple" => {
            "1" => { "address" => { "xml_element_name" => "dc:description", "value" => "The Parade" } },
            "2" => { "address" => { "xml_element_name" => "dc:description", "value" => "Island Bay" } }
          },
          "place_of_birth" => { "xml_element_name" => "dc:subject" },
          "last_name" => "Bloggs"
        }, t.xml_attributes_without_position
      )
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

    model = create_person("address" => { "1" => "Wollaston St.", "2" => "Nelson" }, :do_not_save => true)

    assert_nothing_raised do
      model.save!
    end

    assert_equal [["first_names", "Joe"], ["last_name", "Bloggs"], ["address_multiple", [["Wollaston St."], ["Nelson"]]], ["place_of_birth", nil]].sort, \
                 model.extended_content_pairs.sort
  end

  def test_extended_field_required_fields_are_validated
    # Test with valid fields
    model = create_person("city" => "Wellington")

    assert model.valid?

    assert_nothing_raised do
      model.save!
    end

    # Test with invalid fields
    model = create_person("first_names" => "", "last_name" => "Bloggs Fam.", :do_not_save => true)
    assert_equal [["first_names", nil], ["last_name", "Bloggs Fam."], ["place_of_birth", nil]].sort, model.extended_content_pairs.sort
    assert !model.valid?
    assert_equal 1, model.errors.size

    assert_raises ActiveRecord::RecordInvalid do
      model.save!
    end
  end

  def test_extended_field_required_fields_are_validated_with_multiples
    topic_type = add_field_to(TopicType.find_by_name("Person"), { :label => "Address", :multiple => true }, { :required => true })

    model = create_person("address" => { "1" => "Wollaston St.", "2" => "" })

    assert model.valid?

    model.extended_content_values = default_extended_values_plus("address" => { "1" => "", "2" => "" })

    assert !model.valid?
    assert_equal 1, model.errors.size

    # Drop our newly created field and mapping
    drop_last_field!
  end

  def test_helpers_work
    for_topic_with(TopicType.find_by_name("Person"), { :label => "Address", :ftype => "textarea" }) do |t|
      t.extended_content_values = standard_names
      assert t.valid?
      assert_kind_of Topic, t
    end
  end

  def test_extended_field_text_fields_are_validated
    model = create_person
    assert model.valid?
    assert_equal 0, model.errors.size
  end

  def test_extended_field_textarea_fields_are_validated
    for_topic_with(TopicType.find_by_name("Person"), { :label => "Address", :ftype => "textarea" }) do |t|
      t.extended_content_values = default_extended_values_plus("address" => "New\n Line")
      assert t.valid?
    end
  end

  # TODO: We do not have a plan for how radio fields are to be used in Kete.
  # def test_extended_field_radio_fields_are_validated
  #  print "Skipped"
  # end

  def test_extended_field_date_fields_are_validated
    for_topic_with(TopicType.find_by_name("Person"), { :label => "Birthdate", :ftype => "date" }) do |t|
      t.extended_content_values = default_extended_values_plus("birthdate" => "1960-01-01")
      assert t.valid?

      t.extended_content_values = default_extended_values_plus("birthdate" => "In 1960")
      assert !t.valid?
      assert_equal 1, t.errors.size
      assert_equal "Birthdate must be in the standard date format (YYYY-MM-DD)", t.errors.full_messages.join(", ")

      t.extended_content_values = default_extended_values_plus("birthdate" => "1960-1-1")
      assert !t.valid?
      assert_equal 1, t.errors.size
      assert_equal "Birthdate must be in the standard date format (YYYY-MM-DD)", t.errors.full_messages.join(", ")
    end
  end

  # TODO: add year and circa validation testing
  # TODO: seems we are missing choices tests that have a value that is different than label

  def test_extended_field_checkbox_fields_are_validated
    for_topic_with(TopicType.find_by_name("Person"), { :label => "Deceased", :ftype => "checkbox" }) do |t|
      ["Yes", "No", "yes", "no", ""].each do |value|
        t.extended_content_values = default_extended_values_plus("deceased" => value)
        assert t.valid?
        assert_equal 0, t.errors.size
      end

      [1, 0].each do |value|
        t.extended_content_values = default_extended_values_plus("deceased" => value)
        assert !t.valid?
        assert_equal "Deceased must be a valid checkbox value (Yes or No)", t.errors.full_messages.join(", ")
      end
    end
  end

  def test_extended_field_choice_fields_are_validated
    for_topic_with(TopicType.find_by_name("Person"), { :label => "Marital status", :ftype => "choice" }) do |t|
      set_up_choices

      assert_equal 4, t.all_field_mappings.last.extended_field.choices.size

      # Run the tests
      ["", "Married", "Defacto Relationship", "Dating", "Single"].each do |value|
        t.extended_content_values = default_extended_values_plus("marital_status" => value)
        assert t.valid?
        assert_equal 0, t.errors.size
      end

      ["married", "something else", "123", "Defacto", "Defacto relationship"].each do |v|
        t.extended_content_values = default_extended_values_plus("marital_status" => v)
        assert !t.valid?
        assert_equal 1, t.errors.size
        assert_equal "Marital status must be a valid choice", t.errors.full_messages.join(", ")
      end

      ExtendedField.last.choices.each { |c| c.destroy }
      assert_equal 0, ExtendedField.last.choices.size
    end
  end

  def test_extended_field_topic_type_fields_are_validated
    for_topic_with(TopicType.find_by_name("Person"), { :label => "Father", :ftype => "topic_type" }) do |t|
      father = set_up_father_for_father_field

      t.extended_content_values = default_extended_values_plus("father" => "#{father.title} (#{url_for_dc_identifier(father)})")
      assert t.valid?
      assert_equal 0, t.errors.size

      t.extended_content_values = default_extended_values_plus("father" => "barf")
      assert !t.valid?
      assert_equal 1, t.errors.size
      assert t.errors.full_messages.join(", ").include?(I18n.t('extended_content_lib.validate_extended_topic_type_field_content.no_such_topic', :label => "Father"))
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
    for_topic_with(TopicType.find_by_name("Person"), { :label => "Address", :multiple => true }) do |t|
      t.extended_content_values = default_extended_values_plus("address" => { 
                                                                 "1" => "The Parade",
                                                                 "2" => "Island Bay" 
                                                               })

      assert t.valid?

      expected_hash = default_expected_hash_plus({ "address" => [["The Parade"], ["Island Bay"]] })
      assert_equal expected_hash, t.structured_extended_content
    end
  end

  def test_structured_extended_content_getter_with_ftype_topic_type
    for_topic_with(TopicType.find_by_name("Person"), { :label => "Father", :ftype => 'topic_type' }) do |t|
      father = set_up_father_for_father_field

      title, url = father.title, url_for_dc_identifier(father)

      t.extended_content_values = default_extended_values_plus("father" => "#{title} (#{url})")

      assert t.valid?

      expected_hash = default_expected_hash_plus({ "father" => [{ 
                                                   "label" => title,
                                                   "value" => url 
                                                 }] })
      assert_equal expected_hash, t.structured_extended_content
    end
  end

  def test_structured_extended_content_getter_with_multiple_ftype_topic_type
    for_topic_with(
      TopicType.find_by_name("Person"), { 
        :label => "Relatives",
        :ftype => 'topic_type',
        :multiple => true 
      }
    ) do |t|
      father, mother = set_up_relatives_for_relatives_field

      f_title, f_url, m_title, m_url = [
        father.title,
        url_for_dc_identifier(father),
        mother.title,
        url_for_dc_identifier(mother)]

      t.extended_content_values = default_extended_values_plus("relatives" => { 
                                                                 "1" => "#{f_title} (#{f_url})",
                                                                 "2" => "#{m_title} (#{m_url})" 
                                                               })

      assert t.valid?

      expected_hash = default_expected_hash_plus({ "relatives" => [
                                                   [{ 
                                                     "xml_element_name" => "dc:description",
                                                     "label" => f_title,
                                                     "value" => f_url 
                                                   }],
                                                   [{ 
                                                     "xml_element_name" => "dc:description",
                                                     "label" => m_title,
                                                     "value" => m_url 
                                                   }]] })
      assert_equal expected_hash, t.structured_extended_content
    end
  end

  def test_structured_extended_content_getter_with_choices
    for_topic_with(TopicType.find_by_name("Person"), { :label => "Marital status", :ftype => "choice", :multiple => false }) do |t|
      set_up_choices

      t.extended_content_values = default_extended_values_plus("marital_status" => { 
                                                                 "1" => "Married",
                                                                 "2" => "Dating" 
                                                               })

      assert_equal(
        default_expected_hash_plus("marital_status" => married_dating_as_hashes),
        t.structured_extended_content
      )
    end
  end

  def test_structured_extended_content_getter_with_multiple_choices
    for_topic_with(TopicType.find_by_name("Person"), { :label => "Marital status", :ftype => "choice", :multiple => true }) do |t|
      set_up_choices

      t.extended_content_values = default_extended_values_plus("marital_status" => { "1" => { "1" => "Married", "2" => "Dating" }, "2" => { "1" => "Single" } })

      assert_equal(
        default_expected_hash_plus("marital_status" => married_dating_and_single_as_hashes),
        t.structured_extended_content
      )
    end
  end

  def test_structured_extended_content_getter_with_no_values
    for_topic_with(TopicType.find_by_name("Person"), { :label => "Address", :multiple => true }) do |t|
      t.extended_content = nil

      assert_equal({}, t.structured_extended_content)
    end
  end

  def test_structured_extended_content_setter
    for_topic_with(TopicType.find_by_name("Person"), { :label => "Address", :multiple => true }) do |t|
      t.structured_extended_content = default_expected_hash_plus("address" => [
                                                                   ["The Parade"],
                                                                   ["Island Bay"]])

      assert t.valid?

      expected_value = '<first_names xml_element_name="dc:description">Joe</first_names><last_name>Bloggs</last_name><place_of_birth xml_element_name="dc:subject"></place_of_birth><address_multiple><1><address xml_element_name="dc:description">The Parade</address></1><2><address xml_element_name="dc:description">Island Bay</address></2></address_multiple>'
      assert_equal expected_value, t.extended_content
    end
  end

  def test_structured_extended_content_setter_with_choices
    for_topic_with(TopicType.find_by_name("Person"), { :label => "Marital status", :ftype => "choice", :multiple => false }) do |t|
      set_up_choices

      t.structured_extended_content = default_expected_hash_plus("marital_status" => [married_dating_array])

      expected_hash = default_expected_hash_plus("marital_status" => married_dating_as_hashes)

      assert_equal(expected_hash, t.structured_extended_content)

      expected_value = '<first_names xml_element_name="dc:description">Joe</first_names><last_name>Bloggs</last_name><place_of_birth xml_element_name="dc:subject"></place_of_birth><marital_status xml_element_name="dc:description"><1 label="Married">Married</1><2 label="Dating">Dating</2></marital_status>'

      assert_equal expected_value, t.extended_content
    end
  end

  def test_structured_extended_content_setter_with_multiple_choices
    for_topic_with(TopicType.find_by_name("Person"), { :label => "Marital status", :ftype => "choice", :multiple => true }) do |t|
      set_up_choices

      t.structured_extended_content = default_expected_hash_plus("marital_status" => married_dating_and_single_array)

      expected_hash = default_expected_hash_plus("marital_status" => married_dating_and_single_as_hashes)

      assert_equal(expected_hash, t.structured_extended_content)

      expected_value = '<first_names xml_element_name="dc:description">Joe</first_names><last_name>Bloggs</last_name><place_of_birth xml_element_name="dc:subject"></place_of_birth><marital_status_multiple><1><marital_status xml_element_name="dc:description"><1 label="Married">Married</1><2 label="Dating">Dating</2></marital_status></1><2><marital_status xml_element_name="dc:description"><1 label="Single">Single</1></marital_status></2></marital_status_multiple>'

      assert_equal expected_value, t.extended_content
    end
  end

  def test_structured_extended_content_setter_with_ftype_topic_type
    for_topic_with(TopicType.find_by_name("Person"), { :label => "Father", :ftype => "topic_type" }) do |t|
      father = set_up_father_for_father_field

      title, url = father.title, url_for_dc_identifier(father)

      t.structured_extended_content = default_expected_hash_plus("father" => [{ 
                                                                   "label" => title,
                                                                   "value" => url 
                                                                 }])

      expected_value = "<first_names xml_element_name=\"dc:description\">Joe</first_names><last_name>Bloggs</last_name><place_of_birth xml_element_name=\"dc:subject\"></place_of_birth><father xml_element_name=\"dc:description\" label=\"#{title}\">#{url}</father>"

      assert_equal expected_value, t.extended_content
    end
  end

  def test_structured_extended_content_setter_with_ftype_topic_type_multiple
    for_topic_with(
      TopicType.find_by_name("Person"),
      { 
        :label => "Relatives",
        :ftype => "topic_type",
        :multiple => true 
      }
    ) do |t|

      father, mother = set_up_relatives_for_relatives_field

      f_title, f_url, m_title, m_url = [
        father.title,
        url_for_dc_identifier(father),
        mother.title,
        url_for_dc_identifier(mother)]

      t.structured_extended_content = default_expected_hash_plus("relatives" => [
                                                                   [{ 
                                                                     "label" => f_title,
                                                                     "value" => f_url 
                                                                   }],
                                                                   [{ 
                                                                     "label" => m_title,
                                                                     "value" => m_url 
                                                                   }]])

      expected_value = "<first_names xml_element_name=\"dc:description\">Joe</first_names><last_name>Bloggs</last_name><place_of_birth xml_element_name=\"dc:subject\"></place_of_birth><relatives_multiple><1><relatives xml_element_name=\"dc:description\" label=\"#{f_title}\">#{f_url}</relatives></1><2><relatives xml_element_name=\"dc:description\" label=\"#{m_title}\">#{m_url}</relatives></2></relatives_multiple>"

      assert_equal expected_value, t.extended_content
    end
  end

  # TODO: need accessor tests for date, year (including circa), map ftypes, etc.

  def test_extended_content_accessors_with_text
    for_topic_with(
      TopicType.find_by_name("Person"), { 
        :label => "Job",
        :ftype => "text" 
      }
    ) do |t|
      t.structured_extended_content = default_expected_hash_plus("job" => [["tester"]])

      assert_equal "Joe", t.first_names
      assert_nil t.place_of_birth
      assert_equal "tester", t.job

      t.job = "Software Engineer"
      assert_equal "Software Engineer", t.job

      assert t.extended_content.include?('<job xml_element_name="dc:description">Software Engineer</job>')

      t.send("job+=", " Jr")
      assert_equal "Software Engineer Jr", t.job
    end
  end

  # WARNING: leaving this failing test in place on purpose
  # Walter McGinnis, 2010-11-18
  # my feeling for the multiple text field is that it should
  # return an array of string values
  p "needs enhancement to have test pass"
  def test_extended_content_accessors_with_multiple_text
    for_topic_with(
      TopicType.find_by_name("Person"), { 
        :label => "Past Jobs",
        :ftype => "text",
        :multiple => true 
      }
    ) do |t|
      t.extended_content_values = default_extended_values_plus("past_jobs" => { 
                                                                 "1" => "Janitor",
                                                                 "2" => "Garbageman" 
                                                               })

      assert_equal "Joe", t.first_names
      assert_nil t.place_of_birth
      past_jobs = ['Janitor', 'Garbageman']
      assert_equal past_jobs, t.past_jobs

      past_jobs = ['Gas Station Attendant', 'Paper Shuffler']
      t.past_jobs = past_jobs
      assert_equal past_jobs, t.past_jobs

      assert t.extended_content.include?("<past_jobs_multiple><1><past_jobs xml_element_name=\"dc:description\">Gas Station Attendant</past_jobs></1><2><past_jobs xml_element_name=\"dc:description\">Paper Shuffler</past_jobs></2></past_jobs_multiple>")

      t.send("past_jobs+=", 'Nit Picker')
      past_jobs = past_jobs + ['Nit Picker']
      assert_equal past_jobs, t.past_jobs
    end
  end

  ####### Working version of test, not happy with reader_for returned data structures for text field multiple
  #   def test_extended_content_accessors_with_multiple_text
  #     for_topic_with(TopicType.find_by_name("Person"), { :label => "Past Jobs",
  #                      :ftype => "text",
  #                      :multiple => true}) do |t|
  #       t.extended_content_values = default_extended_values_plus("past_jobs" => { "1" => "Janitor",
  #                                                                  "2" => "Garbageman" })

  #       assert_equal "Joe", t.first_names
  #       assert_nil t.place_of_birth
  #       past_jobs = [['Janitor'], ['Garbageman']]
  #       assert_equal past_jobs, t.past_jobs

  #       past_jobs = [['Gas Station Attendant'], ['Paper Shuffler']]
  #       t.past_jobs = past_jobs
  #       assert_equal past_jobs, t.past_jobs

  #       assert t.extended_content.include?("<past_jobs_multiple><1><past_jobs xml_element_name=\"dc:description\">Gas Station Attendant</past_jobs></1><2><past_jobs xml_element_name=\"dc:description\">Paper Shuffler</past_jobs></2></past_jobs_multiple>")

  #       t.send("past_jobs+=", 'Nit Picker')
  #       past_jobs = past_jobs + [['Nit Picker']]
  #       assert_equal past_jobs , t.past_jobs
  #     end
  #   end

  def test_extended_content_accessors_with_choices
    for_topic_with(TopicType.find_by_name("Person"), { :label => "Marital status", :ftype => "choice", :multiple => false }) do |t|
      set_up_choices

      t.structured_extended_content = default_expected_hash_plus("marital_status" => [married_dating_array])

      assert_equal "Joe", t.first_names
      assert_equal married_dating_array, t.marital_status
      assert_nil t.place_of_birth

      t.marital_status = "Single"
      assert_equal "Single", t.marital_status

      assert t.extended_content.include?('<marital_status xml_element_name="dc:description"><1 label="Single">Single</1></marital_status>')
    end
  end

  def test_extended_content_accessors_with_multiple_choices
    for_topic_with(TopicType.find_by_name("Person"), { :label => "Marital status", :ftype => "choice", :multiple => true }) do |t|
      set_up_choices

      t.structured_extended_content = default_expected_hash_plus("marital_status" => married_dating_and_single_array)

      assert_equal "Joe", t.first_names
      assert_equal married_dating_and_single_array, t.marital_status
      assert_nil t.place_of_birth

      t.marital_status = "Married"
      assert_equal "Married", t.marital_status
      assert t.extended_content.include?("<1><marital_status xml_element_name=\"dc:description\">Married</marital_status></1>")

      t.send("marital_status+=", "Single")
      assert_equal [["Married"], ["Single"]], t.marital_status
      expected = "<1><marital_status xml_element_name=\"dc:description\">Married</marital_status></1>"
      expected += "<2><marital_status xml_element_name=\"dc:description\">Single</marital_status></2>"
      assert t.extended_content.include?(expected), "#{expected} should be in extended content, but isn't. #{t.extended_content}"
    end
  end

  def test_extended_content_accessors_with_ftype_topic_type
    for_topic_with(
      TopicType.find_by_name("Person"),
      { 
        :label => "Father",
        :ftype => "topic_type" 
      }
    ) do |t|
      father = set_up_father_for_father_field

      title, url = father.title, url_for_dc_identifier(father)

      t.structured_extended_content = default_expected_hash_plus("father" => [{ 
                                                                   "label" => title,
                                                                   "value" => url 
                                                                 }])
      assert_equal "Joe", t.first_names
      assert_nil t.place_of_birth
      father_hash = { 'label' => title, 'value' => url }
      assert_equal father_hash, t.father

      father_2 = create_person('first_names' => 'Step Dad')
      f_2_title, f_2_url = father_2.title, url_for_dc_identifier(father_2)

      t.father = "#{f_2_title} (#{f_2_url})"
      father_hash_2 = { 'label' => f_2_title, 'value' => f_2_url }
      assert_equal father_hash_2, t.father

      assert t.extended_content.include?("<father xml_element_name=\"dc:description\" label=\"#{f_2_title}\">#{f_2_url}</father>")
    end
  end

  def test_extended_content_accessors_with_ftype_topic_type_multiple
    for_topic_with(
      TopicType.find_by_name("Person"),
      { 
        :label => "Relatives",
        :ftype => "topic_type",
        :multiple => true 
      }
    ) do |t|
      father, mother = set_up_relatives_for_relatives_field

      f_title, f_url, m_title, m_url = [
        father.title,
        url_for_dc_identifier(father),
        mother.title,
        url_for_dc_identifier(mother)]

      t.structured_extended_content = default_expected_hash_plus("relatives" => [
                                                                   [{ 
                                                                     "label" => f_title,
                                                                     "value" => f_url 
                                                                   }],
                                                                   [{ 
                                                                     "label" => m_title,
                                                                     "value" => m_url 
                                                                   }]])

      assert_equal "Joe", t.first_names
      assert_nil t.place_of_birth
      relatives = [
        [{ 
          'label' => f_title,
          'xml_element_name' => 'dc:description',
          'value' => f_url 
        }],
        [{ 
          'label' => m_title,
          'xml_element_name' => 'dc:description',
          'value' => m_url 
        }]]

      assert_equal relatives, t.relatives

      step_dad = create_person('first_names' => 'Step Dad')
      step_bro = create_person('first_names' => 'Step Brother')

      sd_title, sd_url, sb_title, sb_url = [
        step_dad.title,
        url_for_dc_identifier(step_dad),
        step_bro.title,
        url_for_dc_identifier(step_bro)]

      t.relatives = ["#{sd_title} (#{sd_url})", "#{sb_title} (#{sb_url})"]
      relatives_2 = [
        [{ 
          'label' => sd_title,
          'xml_element_name' => 'dc:description',
          'value' => sd_url 
        }],
        [{ 
          'label' => sb_title,
          'xml_element_name' => 'dc:description',
          'value' => sb_url 
        }]]

      assert_equal relatives_2, t.relatives

      assert t.extended_content.include?("<relatives_multiple><1><relatives xml_element_name=\"dc:description\" label=\"#{sd_title}\">#{sd_url}</relatives></1><2><relatives xml_element_name=\"dc:description\" label=\"#{sb_title}\">#{sb_url}</relatives></2></relatives_multiple>")
    end
  end

  context "A Topic has oembed providable functionality and" do
    setup do
      @topic = Topic.new(@new_model)
      @topic.save
      @topic.creator = User.first
    end

    should "have an oembed_response" do
      assert @topic.respond_to?(:oembed_response)
      assert @topic.oembed_response
    end

    context "supports the required methods needed by oembed and" do
      should "have ability to answer to title and have oembed_response.title" do
        assert @topic.oembed_response.title
        assert_equal @topic.title, @topic.oembed_response.title
      end

      should "have ability to answer to author_name and have oembed_response.author_name" do
        assert @topic.oembed_response.author_name
        assert_equal @topic.author_name, @topic.oembed_response.author_name
      end

      should "have ability to answer to author_url and have oembed_response.author_url" do
        assert @topic.oembed_response.author_url
        assert_equal @topic.author_url, @topic.oembed_response.author_url
      end
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

  def create_person(options = {})
    do_not_save = options.delete(:do_not_save)

    values = standard_names
    values['place_of_birth'] = nil
    values = values.merge(options)

    person = Topic.new(@new_model.merge(:topic_type => TopicType.find_by_name("Person")))
    person.extended_content_values = values
    person.save! unless do_not_save
    person
  end

  def set_up_father_for_father_field
    # set which topic type (Person) for the father field
    ef = ExtendedField.find_by_label('Father')
    ef.settings[:topic_type] = 2

    # create a potential father record
    father = create_person('first_names' => 'Papa')
  end

  def set_up_relatives_for_relatives_field
    # set which topic type (Person) for the father field
    ef = ExtendedField.find_by_label('Relatives')
    ef.settings[:topic_type] = 2

    # create and return our relatives
    [create_person('first_names' => 'Papa'), create_person('first_names' => 'Mama')]
  end

  def standard_names
    { "first_names" => "Joe", "last_name" => "Bloggs" }
  end

  def default_extended_values_plus(options = {})
    standard_names.merge(options)
  end

  def set_up_choices
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
  end

  def married_dating_array
    %w(Married Dating)
  end

  def married_dating_as_hashes(in_array = true)
    values = married_dating_array.collect { |s| { 'label' => s, 'value' => s } }
    if in_array
      [values]
    else
      values
    end
  end

  def single_array
    ['Single']
  end

  def single_hash(in_array = true)
    single = single_array[0]
    hash = { 'label' => single, 'value' => single }
    if in_array
      [hash]
    else
      hash
    end
  end

  def married_dating_and_single_array
    [married_dating_array, single_array]
  end

  def married_dating_and_single_as_hashes
    [married_dating_as_hashes(false), single_hash]
  end

  def default_expected_hash_plus(options = {})
    { 
      "first_names" => [["Joe"]],
      "last_name" => [["Bloggs"]],
      "place_of_birth" => [[nil]] 
    }.merge(options)
  end
end
