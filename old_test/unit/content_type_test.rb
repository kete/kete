require File.dirname(__FILE__) + '/../test_helper'

class ContentTypeTest < ActiveSupport::TestCase
  # fixtures preloaded

  def setup
    @base_class = "ContentType"

    # hash of params to create new instance of model, e.g. {:name => 'Test Model', :description => 'Dummy'}
    @new_model = { :class_name => 'TestType',
                   :controller => 'test_types',
                   :humanized => 'Test Type',
                   :humanized_plural => 'Test Types' }

    # name of fields that must be present, e.g. %(name description)
    @req_attr_names = %w(controller class_name humanized humanized_plural)

    # name of fields that cannot be a duplicate, e.g. %(name description)
    @duplicate_attr_names = %w(controller class_name humanized humanized_plural)
  end

  # load in sets of tests and helper methods
  include KeteTestUnitHelper

  # TODO: <<(extended_field)
  # TODO: <<(required_form_field)
end
