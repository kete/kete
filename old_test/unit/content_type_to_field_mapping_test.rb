require File.dirname(__FILE__) + '/../test_helper'

class ContentTypeToFieldMappingTest < ActiveSupport::TestCase
  (ITEM_CLASSES - ['Topic', 'Comment']).each do |zoom_class|
    context "When the #{zoom_class} content type exists with two extended field mappings (one single value, one multiple)" do
      setup do
        @content_type, @mappings = setup_mappings_of_class('ContentType', zoom_class)
      end

      context "and each mapping isn't being used or it's blank, it" do
        setup do
          @mappings.each do |mapping|
            populate_empty_extended_field_data_for(zoom_class, mapping)
          end
        end

        should "be able to be destroyed" do
          @mappings.each do |mapping|
            assert !mapping.used_by_items?
          end
        end
      end

      context "and each mapping is being used, it" do
        setup do
          @mappings.each do |mapping|
            populate_filled_in_extended_field_data_for(zoom_class, mapping)
          end
        end

        should "not be able to be destroyed" do
          @mappings.each do |mapping|
            assert mapping.used_by_items?
          end
        end
      end
    end

    context "When dealing with required and private_only fields, you" do
      setup do
        @content_type, @mappings = setup_mappings_of_class('ContentType', zoom_class)
      end

      should "not be allowed to have both required and private_only to be enabled" do
        mapping = @mappings.last
        mapping.required = true
        mapping.private_only = true
        assert !mapping.valid?
        assert_equal 'Mapping cannot be required and private only.', mapping.errors['base']
      end
    end
  end

  context "The User content type" do
    context "When dealing with private_only field, you" do
      setup do
        @content_type, @mappings = setup_mappings_of_class('ContentType', 'User')
      end

      should "not be able to set them on User content type" do
        mapping = @mappings.last
        mapping.private_only = true
        assert !mapping.valid?
        assert_equal 'Users cannot have private only mappings.', mapping.errors['base']
      end
    end
  end
end
