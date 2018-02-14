# frozen_string_literal: true

require File.dirname(__FILE__) + '/integration_test_helper'

class ContentTypeTest < ActionController::IntegrationTest
  (ITEM_CLASSES - ['Topic', 'Comment']).each do |zoom_class|
    context "When the #{zoom_class} content type exists with two extended field mappings (one single value/optional, one multiple/required)" do
      setup do
        add_admin_as_super_user
        login_as('admin')
        @content_type, @mappings = setup_mappings_of_class('ContentType', zoom_class, true)
        visit "/site/content_types/edit/#{@content_type.id}"
      end

      should "have the required checkboxes be checked correctly, be able to switch the checkboxes and save, and have them reflected in the form" do
        assert !field_with_id("mapping_#{@mappings.first.id}_required").checked?
        assert field_with_id("mapping_#{@mappings.last.id}_required").checked?

        field_with_id("mapping_#{@mappings.first.id}_required").check
        field_with_id("mapping_#{@mappings.last.id}_required").uncheck

        click_button I18n.t('content_types.current_fields.update_fields')

        assert field_with_id("mapping_#{@mappings.first.id}_required").checked?
        assert !field_with_id("mapping_#{@mappings.last.id}_required").checked?
      end

      context "and each mapping isn't being used or it's blank, it" do
        setup do
          @mappings.each { |m| m.update_attribute(:required, false) }
          @mappings.each do |mapping|
            populate_empty_extended_field_data_for(zoom_class, mapping)
          end
        end

        should "be able to be destroyed" do
          visit "/site/content_types/edit/#{@content_type.id}"
          @mappings.each do |mapping|
            body_should_contain "mapping_#{mapping.id}_delete"
            click_link "mapping_#{mapping.id}_delete"
            body_should_contain "The #{mapping.extended_field.label} mapping has been deleted."
            body_should_not_contain "mapping_#{mapping.id}_delete"
          end
        end
      end

      context "and each mapping is being used, it" do
        setup do
          @mappings.each { |m| m.update_attribute(:required, false) }
          @mappings.each do |mapping|
            populate_filled_in_extended_field_data_for(zoom_class, mapping)
          end
        end

        should "not be able to be destroyed" do
          visit "/site/content_types/edit/#{@content_type.id}"
          @mappings.each do |mapping|
            body_should_not_contain "mapping_#{mapping.id}_delete"
            visit "/site/content_types/remove_mapping/#{@content_type.id}?mapping_id=#{mapping.id}"
            body_should_contain "The #{mapping.extended_field.label} mapping is in use by this Content type or its descendants and cannot be deleted."
          end
        end
      end
    end
  end
end
