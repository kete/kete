require File.dirname(__FILE__) + '/integration_test_helper'

class ExtendedContentTest < ActionController::IntegrationTest
  context "some configured extended fields on topics" do
    setup do
      @@extended_fields, @@topic_types = [], []

      TopicTypeToFieldMapping.destroy_all
      ContentTypeToFieldMapping.destroy_all

      add_james_as_super_user
      login_as("james")

      @with_optional_field = configure_new_topic_type_with_extended_field
      @with_required_field = configure_new_topic_type_with_extended_field(
        :extended_field_label => "Required extended data",
        :extended_field_value_required => true,
        :topic_type_name => "Required test topic type"
      )
    end

    teardown do
      (Topic.find(:all) + @@extended_fields + @@topic_types).each do |item|
        item.destroy
      end
    end

    should "be able to create a record with optional extended content" do
      topic = new_topic :title => "Topic with optional extended content", :topic_type => @with_optional_field.name do
        fill_in "Extended data", :with => "Test value"
      end

      body_should_contain "Extended data"
      body_should_contain "Test value"

      # Check that we can update the topic
      visit "/site/topics/edit/#{topic.to_param}"
      fill_in "Extended data", :with => "Different value"
      click_button "Update"

      body_should_contain "Extended data"
      body_should_contain "Different value"
      body_should_not_contain "Test value"
    end

    should "be able to create a record with required extended content" do
      topic = new_topic :title => "Topic with required extended content", :topic_type => @with_required_field.name do
        fill_in "Required extended data", :with => "Test value"
      end

      body_should_contain "Required extended data"
      body_should_contain "Test value"

      # Check that we can update the topic
      visit "/site/topics/edit/#{topic.to_param}"
      fill_in "Required extended data", :with => "Different value"
      click_button "Update"

      body_should_contain "Required extended data"
      body_should_contain "Different value"
      body_should_not_contain "Test value"

      # Check that validations work
      visit "/site/topics/edit/#{topic.to_param}"
      fill_in "Required extended data", :with => ""
      click_button "Update"

      body_should_contain "Required extended data cannot be blank"
    end

    should "raise validation error when missing required extended content" do
      visit "/site/topics/new"
      select(/Required test topic type/, :from => "topic_topic_type_id")
      click_button "Choose Type"
      fill_in "Title", :with => "Topic missing required extended content"
      fill_in "Description", :with => "Test description"
      click_button "Create"

      body_should_contain "Required extended data cannot be blank"
    end
  end

  (ITEM_CLASSES - ["Topic"]).each do |class_name|
    context "a required extended field configured on #{class_name}" do
      setup do
        add_james_as_super_user
        login_as('james')

        TopicTypeToFieldMapping.destroy_all
        ContentTypeToFieldMapping.destroy_all

        options = {
          :extended_field_value_required => true,
          :extended_field_label => "Extended data for #{class_name}",
          :extended_field_multiple => false,
          :extended_field_ftype => "Text"
        }

        # Add a new extended field
        visit "/"
        click_link "extended fields"
        click_link "Create New"

        fill_in "record_label_", :with => options[:extended_field_label]
        select options[:extended_field_ftype], :from => "record_ftype"
        select options[:extended_field_multiple].to_s.capitalize, :from => "record_multiple"
        click_button "Create"

        assert_equal options[:extended_field_label], ExtendedField.last.label
        @extended_field = ExtendedField.last

        content_type_ids = {
          "AudioRecording" => "2",
          "Document" => "3",
          "StillImage" => "4",
          "Video" => "5",
          "WebLink" => "6"
        }

        visit "/site/content_types/edit/#{content_type_ids[class_name]}"

        verb = options[:extended_field_value_required] ? "required" : "add"
        check "extended_field_#{ExtendedField.last.to_param.to_s}_#{verb}_checkbox"

        click_button "Add to Content Type"

        body_should_contain "#{options[:extended_field_label]}"
        if options[:extended_field_value_required]
          assert field_with_id("mapping_#{ContentTypeToFieldMapping.last.id}_required").checked?
        else
          assert !field_with_id("mapping_#{ContentTypeToFieldMapping.last.id}_required").checked?
        end
      end

      teardown do
        ContentTypeToFieldMapping.last.destroy if ContentTypeToFieldMapping.last
        @extended_field.destroy
      end

      should "create a new #{class_name} with required extended data" do
        send("new_#{class_name.tableize.singularize}".to_sym, :title => "#{class_name} with required extended data") do
          fill_in "Extended data for #{class_name}", :with => "Extended information"
          attach_file_for(class_name)
        end

        body_should_contain "Extended data for #{class_name}"
        body_should_contain "Extended information"
      end

      should "create a new #{class_name} without required extended data and trigger validation" do
        visit "/site/#{zoom_class_controller(class_name)}/new"
        fill_in "Title", :with => "#{class_name} with required extended data"
        fill_in "Description", :with => "A test description"
        fill_in "Extended data for #{class_name}", :with => ""
        attach_file_for(class_name)
        click_button "Create"

        body_should_contain "Extended data for #{class_name} cannot be blank"
      end
    end
  end

  context "Embedded extended field data" do
    setup do
      add_james_as_super_user
      login_as(:james)

      TopicTypeToFieldMapping.destroy_all

      @extended_field = ExtendedField.create!(:label => 'Home Town', :ftype => 'choice', :user_choice_addition => true)
      @topic_type = TopicType.first
      @topic_type.form_fields << @extended_field
      @field_mapping = TopicTypeToFieldMapping.last

      # We need to set the topic_type first, because extended_content= depends on it.
      @topic = Topic.new(:topic_type_id => @topic_type.id)
      @topic.attributes = {
        :title => 'Choice Linking Test',
        :topic_type_id => @topic_type.id,
        :basket_id => @@site_basket.id,
        :extended_content_values => {
          "home_town" => {
            "1" => { "preset" => "", "custom" => "Somewhere way out there" }
          }
        }
      }
      @topic.save
      @topic.creator = @james
    end

    should "show up where it is supposed to" do
      @field_mapping.update_attribute(:embedded, nil)
      visit "/#{@@site_basket.urlified_name}/topics/show/#{@topic.id}"
      assert_have_selector("#secondary-content-wrapper .detail-extended-field-table")
      assert_have_no_selector("#embedded_extended_field_data .detail-extended-field-table")

      @field_mapping.update_attribute(:embedded, false)
      visit "/#{@@site_basket.urlified_name}/topics/show/#{@topic.id}"
      assert_have_selector("#secondary-content-wrapper .detail-extended-field-table")
      assert_have_no_selector("#embedded_extended_field_data .detail-extended-field-table")

      @field_mapping.update_attribute(:embedded, true)
      visit "/#{@@site_basket.urlified_name}/topics/show/#{@topic.id}"
      assert_have_selector("#embedded_extended_field_data .detail-extended-field-table")
      assert_have_no_selector("#secondary-content-wrapper .detail-extended-field-table")
    end
  end

  context "A choice extended field" do
    setup do
      add_james_as_super_user
      login_as(:james)

      TopicTypeToFieldMapping.destroy_all

      @extended_field = ExtendedField.create!(:label => 'Home Town', :ftype => 'choice', :user_choice_addition => true)
      @topic_type = TopicType.first
      @topic_type.form_fields << @extended_field

      # We need to set the topic_type first, because extended_content= depends on it.
      @topic = Topic.new(:topic_type_id => @topic_type.id)
      @topic.attributes = {
        :title => 'Choice Linking Test',
        :topic_type_id => @topic_type.id,
        :basket_id => @@site_basket.id 
      }
      @topic.home_town = "Somewhere way out there"
      @topic.save
      @topic.creator = @james
    end

    should "link the values only when supposed to" do
      @extended_field.update_attribute(:dont_link_choice_values, false)
      visit "/#{@@site_basket.urlified_name}/topics/show/#{@topic.id}"
      body_should_contain 'Home Town:'
      body_should_contain Regexp.new("<a .+>Somewhere way out there</a>")

      @extended_field.update_attribute(:dont_link_choice_values, true)
      visit "/#{@@site_basket.urlified_name}/topics/show/#{@topic.id}"
      body_should_contain 'Home Town:'
      body_should_not_contain Regexp.new("<a .+>Somewhere way out there</a>")
      body_should_contain "Somewhere way out there"
    end
  end

  context "A year extended field type" do
    setup do
      add_james_as_super_user
      login_as(:james)

      TopicTypeToFieldMapping.destroy_all

      options = { :ftype => 'year', :circa => true }
      @year_non_multiple = ExtendedField.create!(options.merge(:label => 'Publishing Year', :multiple => false))
      @year_multiple = ExtendedField.create!(options.merge(:label => 'Republishing Years', :multiple => true))
      @topic_type = TopicType.first
      @topic_type.form_fields << @year_non_multiple
      @topic_type.form_fields << @year_multiple
    end

    should "should be correctly validated" do
      new_topic(
        :title => 'Year Extended Field Test',
        :extended_content_values_publishing_year => 'not valid',
        :extended_content_values_republishing_years_1 => 'not valid',
        :should_fail => true
      )
      body_should_contain Regexp.new("Publishing Year must be in the standard year format \\(YYYY\\)")
      body_should_contain Regexp.new("Republishing Years must be in the standard year format \\(YYYY\\)")
    end

    should "correctly store and display the year field for non-multiples and multiples alike" do
      new_topic(
        :title => 'Year Extended Field Test',
        :extended_content_values_publishing_year => '1970',
        :extended_content_values_republishing_years_1 => '2002'
      )
      body_should_contain Regexp.new("<td[^>]*>Publishing Year:</td><td>1970</td>")
      body_should_contain Regexp.new("<td[^>]*>Republishing Years:</td><td>2002</td>")
    end

    context "when those extended fields are required" do
      setup do
        TopicTypeToFieldMapping.destroy_all
        @topic_type.required_form_fields << @year_non_multiple
        @topic_type.required_form_fields << @year_multiple
      end

      should "require the year field to be present for non-multiples and multiples alike" do
        new_topic(:title => 'Year Extended Field Test', :should_fail => true)
        body_should_contain Regexp.new("Publishing Year cannot be blank")
        body_should_contain Regexp.new("Republishing Years must have at least one value")
      end
    end
  end

  private

    def configure_new_topic_type_with_extended_field(options = {})
      options = {
        :extended_field_value_required => false,
        :extended_field_label => "Extended data",
        :extended_field_multiple => false,
        :extended_field_ftype => "Text",
        :topic_type_name => "Test topic type #{(rand * 100000).floor}",
        :topic_type_description => "Topic type description"
      }.merge(options)

      # Add a new extended field
      click_link "extended fields"
      click_link "Create New"

      fill_in "record_label_", :with => options[:extended_field_label]
      select options[:extended_field_ftype], :from => "record_ftype"
      select options[:extended_field_multiple].to_s.capitalize, :from => "record_multiple"
      click_button "Create"

      assert_equal options[:extended_field_label], ExtendedField.last.label
      @@extended_fields << ExtendedField.last

      visit "/site/topic_types/new?parent_id=1"
      fill_in "Name", :with => options[:topic_type_name]
      fill_in "Description", :with => options[:topic_type_description]
      click_button "Create"

      verb = options[:extended_field_value_required] ? "required" : "add"
      check "extended_field_#{ExtendedField.last.to_param.to_s}_#{verb}_checkbox"
      click_button "Add to Topic Type"

      body_should_contain "#{options[:extended_field_label]}"
      if options[:extended_field_value_required]
        assert field_with_id("mapping_#{TopicTypeToFieldMapping.last.id}_required").checked?
      else
        assert !field_with_id("mapping_#{TopicTypeToFieldMapping.last.id}_required").checked?
      end

      assert_equal options[:topic_type_name], TopicType.last.name
      @@topic_types << TopicType.last

      return TopicType.last
    end

    def attach_file_for(zoom_class_name)
      # get the attribute that defines each class
      if ATTACHABLE_CLASSES.include?(zoom_class_name)
        # put in a case statement
        case zoom_class_name
        when 'StillImage'
          attach_file "image_file_uploaded_data", "white.jpg"
        when 'Video'
          attach_file "video[uploaded_data]", "teststrip.mpg", "video/mpeg"
        when 'AudioRecording'
          attach_file "audio_recording[uploaded_data]", "Sin1000Hz.mp3"
        when 'Document'
          attach_file "document[uploaded_data]", "test.pdf"
        end
      elsif zoom_class_name == 'WebLink'
        # this will only work if you have internet connection
        WebLink.find_by_url("http://google.co.nz/").destroy rescue true
        fill_in "web_link[url]", :with => "http://google.co.nz/"
      end
    end
end
